//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flash.geom.Matrix;
import flash.geom.Point;

import flump.MatrixUtil;
import flump.mold.KeyframeMold;

import com.threerings.util.XmlUtil;

public class XflKeyframe
{
    use namespace xflns;

    public static function parse (lib :XflLibrary, baseLocation :String, xml :XML, flipbook :Boolean) :KeyframeMold {
        const kf :KeyframeMold = new KeyframeMold();
        kf.index = XmlUtil.getIntAttr(xml, "index");
        kf.location = baseLocation + ":" + kf.index;
        kf.duration = XmlUtil.getNumberAttr(xml, "duration", 1);
        kf.label = XmlUtil.getStringAttr(xml, "name", null);
        kf.ease = XmlUtil.getNumberAttr(xml, "acceleration", 0) / 100;

        if (flipbook) return kf;
        var symbolXml :XML;
        for each (var frameEl :XML in xml.elements.elements()) {
            if (frameEl.name().localName == "DOMSymbolInstance") {
                if (symbolXml != null)  {
                    lib.addError(kf, ParseError.CRIT, "There can be only one symbol instance at " +
                        "a time in a keyframe.");
                } else symbolXml = frameEl;
            } else {
                lib.addError(kf, ParseError.CRIT, "Non-symbols may not be in movie layers");
            }
        }

        if (symbolXml == null) return kf; // Purely labelled frame

        if (XmlUtil.hasChild(xml, "tweens")) {
            lib.addError(kf, ParseError.WARN, "Custom easing is not supported");
        }

        kf.id = kf.libraryItem = XmlUtil.getStringAttr(symbolXml, "libraryItemName");
        kf.visible = XmlUtil.getBooleanAttr(symbolXml, "isVisible", true);

        var matrix :Matrix = new Matrix();

        // Read the matrix transform
        if (symbolXml.matrix != null) {
            const matrixXml :XML = symbolXml.matrix.Matrix[0];
            function m (name :String, def :Number) :Number {
                return matrixXml == null ? def : XmlUtil.getNumberAttr(matrixXml, name, def);
            }
            matrix = new Matrix(m("a", 1), m("b", 0), m("c", 0), m("d", 1), m("tx", 0), m("ty", 0));

            // Back out of translation
            var rewound :Matrix = matrix.clone();
            rewound.tx = rewound.ty = 0;

            // handle "motionTweenRotate" (in this case, the rotation is not embedded in the matrix)
            if (XmlUtil.hasAttr(xml, "motionTweenRotateTimes") &&
                    XmlUtil.hasAttr(xml, "motionTweenRotate") && kf.duration > 1) {
                kf.rotation = XmlUtil.getNumberAttr(xml, "motionTweenRotateTimes") * Math.PI * 2;
                if (XmlUtil.getStringAttr(xml, "motionTweenRotate") == "clockwise") {
                    kf.rotation *= -1;
                }
                MatrixUtil.setRotation(matrix, kf.rotation);

            } else {
                var p0 :Point = rewound.transformPoint(new Point(0, 0));
                var p1 :Point = rewound.transformPoint(new Point(1, 0));
                kf.rotation = Math.atan2(p1.y - p0.y, p1.x - p0.x);
            }

            // Back out of rotation
            rewound.rotate(-kf.rotation);

            p0 = rewound.transformPoint(new Point(0, 0));
            p1 = rewound.transformPoint(new Point(1, 1));

            kf.scaleX = round(p1.x - p0.x);
            kf.scaleY = round(p1.y - p0.y);
            kf.rotation = round(kf.rotation);

            // var skewX :Number = p1.x - 1;
            // var skewY :Number = p1.y - 1;
        }

        // Read the pivot point
        if (symbolXml.transformationPoint != null) {
            var pivotXml :XML = symbolXml.transformationPoint.Point[0];
            if (pivotXml != null) {
                kf.pivotX = XmlUtil.getNumberAttr(pivotXml, "x", 0);
                kf.pivotY = XmlUtil.getNumberAttr(pivotXml, "y", 0);

                // Translate to the pivot point
                var orig :Matrix = matrix.clone();
                matrix.identity();
                matrix.translate(kf.pivotX, kf.pivotY);
                matrix.concat(orig);
            }
        }

        // Now that the matrix and pivot point have been read, apply translation
        kf.x = round(matrix.tx);
        kf.y = round(matrix.ty);

        // Read the alpha
        if (symbolXml.color != null) {
            var colorXml :XML = symbolXml.color.Color[0];
            if (colorXml != null) {
                kf.alpha = XmlUtil.getNumberAttr(colorXml, "alphaMultiplier", 1);
            }
        }
        return kf;
    }

    protected static function round (n :Number, places :int = 4) :Number {
        var shift :int = Math.pow(10, places);
        return Math.round(n*shift) / shift;
    }
}
}
