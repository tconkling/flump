//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flash.geom.Matrix;

import flump.MatrixUtil;

public class XflKeyframe extends XflComponent
{
    use namespace xflns;

    public var index :int;

    /** The length of this keyframe in frames. */
    public var duration :Number;

    /** The name of the libraryItem in this keyframe, or null if there is no libraryItem. */
    public var libraryItem :String;

    /** The name of the symbol in this keyframe, or null if there is no symbol. */
    public var symbol :String;

    /** The label on this keyframe, or null if there isn't one */
    public var label :String;

    /** Exploded values from matrix */
    public var x :Number = 0.0, y :Number = 0.0, scaleX :Number = 1.0, scaleY :Number = 1.0,
        rotation :Number = 0.0;

    /** Transformation point */
    public var pivotX :Number = 0.0, pivotY :Number = 0.0;

    public var alpha :Number = 1;

    public var visible :Boolean = true;

    public function XflKeyframe (baseLocation :String, xml :XML, errors :Vector.<ParseError>,
        flipbook :Boolean) {
        const converter :XmlConverter = new XmlConverter(xml);
        index = converter.getIntAttr("index");
        super(baseLocation + ":" + index, errors);
        duration = converter.getNumberAttr("duration", 1);
        label = converter.getStringAttr("name", null);

        if (flipbook) return;
        var symbolXml :XML;
        for each (var frameEl :XML in xml.elements.elements()) {
            if (frameEl.name().localName == "DOMSymbolInstance") {
                if (symbolXml != null)  {
                    addError(ParseError.CRIT, "There can be only one symbol instance at " +
                        "a time in a keyframe.");
                } else symbolXml = frameEl;
            } else {
                addError(ParseError.CRIT, "Non-symbols may not be in exported movie " +
                    "layers");
            }
        }

        if (symbolXml == null) return; // Purely labelled frame

        var symbolConverter :XmlConverter = new XmlConverter(symbolXml);
        libraryItem = symbolConverter.getStringAttr("libraryItemName");
        visible = symbolConverter.getBooleanAttr("isVisible", true);

        var matrix :Matrix = new Matrix();

        // Read the matrix transform
        if (symbolXml.matrix != null) {
            const matrixXml :XML = symbolXml.matrix.Matrix[0];
            const matrixConverter :XmlConverter =
                matrixXml == null ? null : new XmlConverter(matrixXml);
            function m (name :String, def :Number) :Number {
                return matrixConverter == null ? def : matrixConverter.getNumberAttr(name, def);
            }
            matrix = new Matrix(m("a", 1), m("b", 0), m("c", 0), m("d", 1), m("tx", 0), m("ty", 0));

            // handle "motionTweenRotate" (in this case, the rotation is not embedded in the matrix)
            if (converter.hasAttr("motionTweenRotateTimes") && duration > 1) {
                rotation = converter.getNumberAttr("motionTweenRotateTimes") * Math.PI * 2;
                if (converter.getStringAttr("motionTweenRotate") == "clockwise") {
                    rotation *= -1;
                }

                MatrixUtil.setRotation(matrix, rotation);
            } else {
                rotation = MatrixUtil.rotation(matrix);
            }

            scaleX = MatrixUtil.scaleX(matrix);
            scaleY = MatrixUtil.scaleY(matrix);
        }

        // Read the pivot point
        if (symbolXml.transformationPoint != null) {
            var pivotXml :XML = symbolXml.transformationPoint.Point[0];
            if (pivotXml != null) {
                var pivotConverter :XmlConverter = new XmlConverter(pivotXml);
                pivotX = pivotConverter.getNumberAttr("x", 0);
                pivotY = pivotConverter.getNumberAttr("y", 0);

                // Translate to the pivot point
                var orig :Matrix = matrix.clone();
                matrix.identity();
                matrix.translate(pivotX, pivotY);
                matrix.concat(orig);
            }
        }

        // Now that the matrix and pivot point have been read, apply translation
        x = matrix.tx;
        y = matrix.ty;

        // Read the alpha
        if (symbolXml.color != null) {
            var colorXml :XML = symbolXml.color.Color[0];
            if (colorXml != null) {
                var colorConverter :XmlConverter = new XmlConverter(colorXml);
                alpha = colorConverter.getNumberAttr("alphaMultiplier", 1);
            }
        }
    }

    public function checkSymbols (lib :XflLibrary) :void {
        if (symbol != null && !lib.hasSymbol(symbol)) {
            addError(ParseError.CRIT, "Symbol '" + symbol + "' not exported");
        }
    }

    public function toJSON (_:*) :Object {
        var json :Object = {
            duration: duration
        };
        if (symbol != null) {
            json.ref = symbol;
            if (x != 0 || y != 0) {
                json.loc = x + "," + y;
            }
            if (scaleX != 1 || scaleY != 1) {
                json.scale = scaleX + "," + scaleY;
            }
            if (rotation != 0) {
                json.rotation = rotation;
            }
            if (pivotX != 0 || pivotY != 0) {
                json.pivot = pivotX + "," + pivotY;
            }
            if (alpha != 1) {
                json.alpha = alpha;
            }
            if (!visible) {
                json.visible = visible;
            }
        }
        if (label != null) {
            json.label = label;
        }
        return json;
    }

    public function toXML () :XML
    {
        var xml :XML = <kf duration={duration}/>;

        if (symbol != null) {
            xml.@ref = symbol;
            if (x != 0 || y != 0) {
                xml.@loc = "" + x + "," + y;
            }
            if (scaleX != 1 || scaleY != 1) {
                xml.@scale = "" + scaleX + "," + scaleY;
            }
            if (rotation != 0) {
                xml.@rotation = rotation;
            }
            if (pivotX != 0 || pivotY != 0) {
                xml.@pivot = "" + pivotX + "," + pivotY;
            }
            if (alpha != 1) {
                xml.@alpha = alpha;
            }
            if (!visible) {
                xml.@visible = visible;
            }
        }
        if (label != null) {
            xml.@label = label;
        }
        return xml;
    }
}
}
