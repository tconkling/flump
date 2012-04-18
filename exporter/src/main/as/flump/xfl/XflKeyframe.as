//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flash.geom.Matrix;
import flash.geom.Point;

import flump.mold.KeyframeMold;
import flump.MatrixUtil;

import com.threerings.util.XmlUtil;

public class XflKeyframe
{
    use namespace xflns;

    public static function parse (lib :XflLibrary, baseLocation :String, xml :XML,
        flipbook :Boolean) :KeyframeMold {

        const kf :KeyframeMold = new KeyframeMold();
        kf.index = XmlUtil.getIntAttr(xml, "index");
        const location :String = baseLocation + ":" + kf.index;
        kf.duration = XmlUtil.getNumberAttr(xml, "duration", 1);
        kf.label = XmlUtil.getStringAttr(xml, "name", null);
        kf.ease = XmlUtil.getNumberAttr(xml, "acceleration", 0) / 100;

        if (flipbook) return kf;
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

            trace("Original matrix: " + matrix);

            // Back out of translation
            var rewound :Matrix = matrix.clone();
            rewound.tx = rewound.ty = 0;

            // var p :Point = rewound.transformPoint(new Point(0, 1));
            // var rotation :Number = Math.atan2(p.y, p.x);

            // rewound = new Matrix();
            // rewound.rotate(-rotation);
            // rewound.concat(matrix);

            // var p0 :Point = rewound.transformPoint(new Point(0, 0));
            // var p1 :Point = rewound.transformPoint(new Point(1, 1));
            // kf.scaleX = p1.x - p0.x;
            // kf.scaleY = p1.x - p0.x;
            // kf.skewX = p1.x - 1;
            // kf.skewY = p1.y - 1;

            // var p :Point = rewound.transformPoint(new Point(0, 1));
            // // var rotation :Number = Math.atan2(p.y, p.x);
            // kf.skewX = Math.atan2(p.y, p.x) - Math.PI/2;

            // p = rewound.transformPoint(new Point(1, 0));
            // kf.skewY = Math.atan2(p.y, p.x);

            // // Back out of rotation
            // rewound.rotate(-kf.skewY);

            // p = rewound.transformPoint(new Point(1, 1));
            // kf.scaleX = p.x;
            // kf.scaleY = p.y;

            var rotation :Number = MatrixUtil.rotation(matrix);
            kf.skewX = MatrixUtil.skewX(rewound);
            kf.skewY = MatrixUtil.skewY(rewound);

            // kf.skewX = Math.atan2(-rewound.c, rewound.d);
            // kf.skewY = Math.atan2(rewound.b, rewound.a);

            // // Back out of skew/rotation
            // var skewMatrix :Matrix = new Matrix();
            // skewMatrix.a = Math.cos(kf.skewY);
            // skewMatrix.b = Math.sin(kf.skewY);
            // skewMatrix.c = -Math.sin(kf.skewX);
            // skewMatrix.d = Math.cos(kf.skewX);
            // skewMatrix.invert();

            // // Back out of skew/rotation
            // MatrixUtil.prepend(rewound, skewMatrix);
            // skewMatrix.a = Math.cos(-kf.skewY);
            // skewMatrix.b = Math.sin(-kf.skewY);
            // skewMatrix.c = -Math.sin(-kf.skewX);
            // skewMatrix.d = Math.cos(-kf.skewX);
            // rewound.concat(skewMatrix);
            trace("Rewound matrix: " + rewound);

            // if (Math.abs(Math.cos(kf.skewY)) > 0.0001) {
            //     kf.scaleX = rewound.a / Math.cos(kf.skewY);
            // } else {
            //     kf.scaleX = rewound.b / Math.sin(kf.skewY);
            // }
            // if (Math.abs(Math.sin(kf.skewX)) > 0.0001) {
            //     kf.scaleY = rewound.c / -Math.sin(kf.skewX);
            // } else {
            //     kf.scaleY = rewound.d / Math.cos(kf.skewX);
            // }

            // kf.scaleX = rewound.c / -Math.sin(kf.skewX);
            // kf.scaleY = rewound.b / Math.sin(kf.skewY);

            // var p :Point = rewound.transformPoint(new Point(1, 1));
            // kf.scaleX = p.x;
            // kf.scaleY = p.y;

            kf.scaleX = MatrixUtil.scaleX(rewound);
            kf.scaleY = MatrixUtil.scaleY(rewound);
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

        trace(location + " translate: " + kf.x + ", "  + kf.y);
        trace(location + " skew: " + kf.skewX + ", " + kf.skewY);
        trace(location + " scale: " + kf.scaleX + ", " + kf.scaleY);
        trace();

        // Read the alpha
        if (symbolXml.color != null) {
            const colorXml :XML = symbolXml.color.Color[0];
            if (colorXml != null) {
                kf.alpha = XmlUtil.getNumberAttr(colorXml, "alphaMultiplier", 1);
            }
        }
        return kf;
    }
}
}
