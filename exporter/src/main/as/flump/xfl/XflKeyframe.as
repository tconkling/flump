//
// Flump - Copyright 2013 Flump Authors

package flump.xfl {

import fl.motion.AdjustColor;
import flash.filters.BevelFilter;
import flash.filters.BitmapFilter;
import flash.filters.BlurFilter;
import flash.filters.ColorMatrixFilter;
import flash.filters.DropShadowFilter;
import flash.filters.GlowFilter;
import flash.geom.Matrix;
import flash.utils.Dictionary;

import flump.mold.KeyframeMold;

import com.threerings.util.MatrixUtil;
import com.threerings.util.XmlUtil;

public class XflKeyframe
{
    use namespace xflns;

    public static function parse (lib :XflLibrary, baseLocation :String, xml :XML,
        flipbook :Boolean) :KeyframeMold {

        const kf :KeyframeMold = new KeyframeMold();
        kf.index = XmlUtil.getIntAttr(xml, "index");
        const location :String = baseLocation + ":" + (kf.index + 1);
        kf.duration = XmlUtil.getNumberAttr(xml, "duration", 1);
        kf.label = XmlUtil.getStringAttr(xml, "name", null);
        kf.ease = XmlUtil.getNumberAttr(xml, "acceleration", 0) / 100;

        const tweenType :String = XmlUtil.getStringAttr(xml, "tweenType", null);
        kf.tweened = (tweenType != null);
        if (tweenType != null && tweenType != "motion") {
            lib.addError(location, ParseError.WARN, "Unrecognized tweenType '" + tweenType + "'");
        }

        if (flipbook) {
            if (xml.elements.elements().length() == 0) {
                lib.addError(location, ParseError.CRIT, "Empty frames are not allowed in flipbooks");
            }
            return kf;
        }

        var symbolXml :XML;
        for each (var frameEl :XML in xml.elements.elements()) {
            if (frameEl.name().localName == "DOMSymbolInstance") {
                if (symbolXml != null)  {
                    lib.addError(location, ParseError.CRIT, "There can be only one symbol instance at " +
                        "a time in a keyframe.");
                } else symbolXml = frameEl;
            } else {
                lib.addError(location, ParseError.CRIT, "Non-symbols may not be in movie layers");
            }
        }

        if (symbolXml == null) return kf; // Purely labelled frame

        if (XmlUtil.getBooleanAttr(xml, "motionTweenOrientToPath", false)) {
            lib.addError(location, ParseError.WARN, "Motion paths are not supported");
        }

        if (XmlUtil.getBooleanAttr(xml, "hasCustomEase", false)) {
            lib.addError(location, ParseError.WARN, "Custom easing is not supported");
        }

        // Fill this in with the library name for now. XflLibrary.finishLoading will swap in the
        // symbol or implicit symbol the library item corresponds to.
        kf.ref = XmlUtil.getStringAttr(symbolXml, "libraryItemName");
        kf.visible = XmlUtil.getBooleanAttr(symbolXml, "isVisible", true);

        var matrix :Matrix = new Matrix();

        // Read the matrix transform
        if (symbolXml.matrix != null) {
            const matrixXml :XML = symbolXml.matrix.Matrix[0];
            function m (name :String, def :Number) :Number {
                return matrixXml == null ? def : XmlUtil.getNumberAttr(matrixXml, name, def);
            }
            matrix = new Matrix(m("a", 1), m("b", 0), m("c", 0), m("d", 1), m("tx", 0), m("ty", 0));

            kf.scaleX = MatrixUtil.scaleX(matrix);
            kf.scaleY = MatrixUtil.scaleY(matrix);
            kf.skewX = MatrixUtil.skewX(matrix);
            kf.skewY = MatrixUtil.skewY(matrix);
        }

        // Read the pivot point
        if (symbolXml.transformationPoint != null) {
            var pivotXml :XML = symbolXml.transformationPoint.Point[0];
            if (pivotXml != null) {
                kf.pivotX = XmlUtil.getNumberAttr(pivotXml, "x", 0);
                kf.pivotY = XmlUtil.getNumberAttr(pivotXml, "y", 0);

                // Translate to the pivot point
                const orig :Matrix = matrix.clone();
                matrix.identity();
                matrix.translate(kf.pivotX, kf.pivotY);
                matrix.concat(orig);
            }
        }

        // Now that the matrix and pivot point have been read, apply translation
        kf.x = matrix.tx;
        kf.y = matrix.ty;

        // Read the alpha
        if (symbolXml.color != null) {
            const colorXml :XML = symbolXml.color.Color[0];
            if (colorXml != null) {
                kf.alpha = XmlUtil.getNumberAttr(colorXml, "alphaMultiplier", 1);
            }
        }

        parseFilters(lib, location, kf, symbolXml);

        return kf;
    }

    // Parse filters for this symbol+keyframe, store them in a static lookup table
    protected static function parseFilters (lib :XflLibrary, location :String, kf :KeyframeMold, symbolXml :XML) :void {
        // if filter list is empty, early out
        if (symbolXml.filters == null) {
            return;
        }

        // initialize lookup table entry
        _filtersByKeyframe[kf] = [];

        // for each filter nodes, parse the xml and add a BitmapFilter to the lookup table
        var filter:BitmapFilter;
        for each (var filterXml:XML in symbolXml.filters.elements()) {
            // parse different filter types into their native flash.filter types
            if (filterXml.name().localName == "AdjustColorFilter") {
                // <AdjustColorFilter brightness="-100" hue="-32"/>
                var colorFilter:AdjustColor = new AdjustColor();
                colorFilter.hue = XmlUtil.getNumberAttr(filterXml, "hue", 0);
                colorFilter.saturation = XmlUtil.getNumberAttr(filterXml, "saturation", 0);
                colorFilter.brightness = XmlUtil.getNumberAttr(filterXml, "brightness", 0);
                colorFilter.contrast = XmlUtil.getNumberAttr(filterXml, "contrast", 0);
                var mMatrix:Array = colorFilter.CalculateFinalFlatArray();
                filter = new ColorMatrixFilter(mMatrix);
                _filtersByKeyframe[kf].push(filter);
            } else if (filterXml.name().localName == "BlurFilter") {
                // <BlurFilter blurX="4" blurY="4" quality="2"/>
                filter = new BlurFilter(
                    XmlUtil.getNumberAttr(filterXml, "blurX", 5),
                    XmlUtil.getNumberAttr(filterXml, "blurY", 5),
                    XmlUtil.getNumberAttr(filterXml, "quality", 1)
                );
                _filtersByKeyframe[kf].push(filter);
            } else if (filterXml.name().localName == "BevelFilter") {
                // <BevelFilter blurX="11" blurY="11" quality="2" angle="80.0000022767297" distance="-7" 
                // highlightColor="#33FF00" shadowColor="#CC00FF" strength="1.28"/>
                filter = new BevelFilter(
                    XmlUtil.getNumberAttr(filterXml, "distance", 5.0),
                    XmlUtil.getNumberAttr(filterXml, "angle", 45),
                    parseInt(XmlUtil.getStringAttr(filterXml, "highlightColor", "#ffffff").substr(1), 16),
                    XmlUtil.getNumberAttr(filterXml, "highlightAlpha", 1.0),
                    parseInt(XmlUtil.getStringAttr(filterXml, "shadowColor", "#000000").substr(1), 16),
                    XmlUtil.getNumberAttr(filterXml, "shadowAlpha", 1.0),
                    XmlUtil.getNumberAttr(filterXml, "blurX", 5),
                    XmlUtil.getNumberAttr(filterXml, "blurY", 5),
                    XmlUtil.getNumberAttr(filterXml, "strength", 1),
                    XmlUtil.getNumberAttr(filterXml, "quality", 1),
                    XmlUtil.getStringAttr(filterXml, "type", "inner"),
                    XmlUtil.getBooleanAttr(filterXml, "knockout", false)
                );
                _filtersByKeyframe[kf].push(filter);
            } else if (filterXml.name().localName == "DropShadowFilter") {
                // <DropShadowFilter angle="15.9999994308176" blurX="12" blurY="12" color="#9933CC" 
                // distance="18" hideObject="true" inner="true" knockout="true" quality="3" strength="0.77"/>
                filter = new DropShadowFilter(
                    XmlUtil.getNumberAttr(filterXml, "distance", 5.0),
                    XmlUtil.getNumberAttr(filterXml, "angle", 45),
                    parseInt(XmlUtil.getStringAttr(filterXml, "color", "#000000").substr(1), 16),
                    XmlUtil.getNumberAttr(filterXml, "alpha", 1.0),
                    XmlUtil.getNumberAttr(filterXml, "blurX", 5),
                    XmlUtil.getNumberAttr(filterXml, "blurY", 5),
                    XmlUtil.getNumberAttr(filterXml, "strength", 1),
                    XmlUtil.getNumberAttr(filterXml, "quality", 1),
                    XmlUtil.getBooleanAttr(filterXml, "inner", false),
                    XmlUtil.getBooleanAttr(filterXml, "knockout", false),
                    XmlUtil.getBooleanAttr(filterXml, "hideObject", false)
                );
                _filtersByKeyframe[kf].push(filter);
            } else if (filterXml.name().localName == "GlowFilter") {
                // <GlowFilter blurX="6" blurY="6" color="#00CC66" inner="true" knockout="true" quality="2" strength="0.9"/>
                filter = new GlowFilter(
                    parseInt(XmlUtil.getStringAttr(filterXml, "color", "#ff0000").substr(1), 16),
                    XmlUtil.getNumberAttr(filterXml, "alpha", 1),
                    XmlUtil.getNumberAttr(filterXml, "blurX", 5),
                    XmlUtil.getNumberAttr(filterXml, "blurY", 5),
                    XmlUtil.getNumberAttr(filterXml, "strength", 1),
                    XmlUtil.getNumberAttr(filterXml, "quality", 1),
                    XmlUtil.getBooleanAttr(filterXml, "inner", false),
                    XmlUtil.getBooleanAttr(filterXml, "knockout", false)
                );
                _filtersByKeyframe[kf].push(filter);
            } else {
                // parsing for this filter type is unimplemented
                lib.addError(location, ParseError.WARN, "Unimplemented parsing for filter type: '" + filterXml.name().localName + "'");
            }

            // if we only parsed unsupported filter types, remove the lookup table entry
            if (_filtersByKeyframe[kf].length == 0) {
                delete _filtersByKeyframe[kf];
            }
        }
    }

    // lookup table for filters associated with a given KeyframeMold
    static private var _filtersByKeyframe:Dictionary = new Dictionary(true);
    static public function getFiltersForKeyframe(kf:KeyframeMold):Array
    {
        return (kf in _filtersByKeyframe) ? _filtersByKeyframe[kf] : null;
    }

}
}
