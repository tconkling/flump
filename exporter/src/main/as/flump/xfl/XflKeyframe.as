//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flash.geom.Matrix;

import flump.MatrixUtil;
import flump.mold.KeyframeMold;
import flump.mold.ParseError;

public class XflKeyframe extends KeyframeMold
{
    use namespace xflns;

    public function XflKeyframe (baseLocation :String, xml :XML, errors :Vector.<ParseError>,
        flipbook :Boolean) {
        const converter :XmlConverter = new XmlConverter(xml);
        index = converter.getIntAttr("index");
        location = baseLocation + ":" + index;
        super(errors);
        duration = converter.getNumberAttr("duration", 1);
        label = converter.getStringAttr("name", null);
        ease = converter.getNumberAttr("acceleration", 0) / 100;

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

        if (xml.tweens != null) {
            addError(ParseError.WARN, "Custom easing is not supported");
        }

        var symbolConverter :XmlConverter = new XmlConverter(symbolXml);
        id = libraryItem = symbolConverter.getStringAttr("libraryItemName");
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
            if (converter.hasAttr("motionTweenRotateTimes") &&
                    converter.hasAttr("motionTweenRotate") && duration > 1) {
                rotation = converter.getNumberAttr("motionTweenRotateTimes") * Math.PI * 2;
                if (converter.getStringAttr("motionTweenRotate") == "clockwise") {
                    rotation *= -1;
                }

                MatrixUtil.setRotation(matrix, rotation);
            } else {
                rotation = MatrixUtil.rotation(matrix);
            }

            rotation = round(rotation);
            scaleX = round(MatrixUtil.scaleX(matrix));
            scaleY = round(MatrixUtil.scaleY(matrix));
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
        x = round(matrix.tx);
        y = round(matrix.ty);

        // Read the alpha
        if (symbolXml.color != null) {
            var colorXml :XML = symbolXml.color.Color[0];
            if (colorXml != null) {
                var colorConverter :XmlConverter = new XmlConverter(colorXml);
                alpha = colorConverter.getNumberAttr("alphaMultiplier", 1);
            }
        }
    }

    protected static function round (n :Number, places :int = 4) :Number {
        var shift :int = Math.pow(10, places);
        return Math.round(n*shift) / shift;
    }
}
}
