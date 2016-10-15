//
// Flump - Copyright 2013 Flump Authors

package flump.xfl {

import aspire.util.XmlUtil;

import flump.mold.KeyframeMold;
import flump.mold.LayerMold;

public class XflLayer
{
    public static const NAME :String = "name";
    public static const TYPE :String = "layerType";

    public static const TYPE_GUIDE :String = "guide";
    public static const TYPE_FOLDER :String = "folder";
	public static const TYPE_MASK :String = "mask";

    use namespace xflns;

    public static function parse (lib :XflLibrary, baseLocation :String, xml :XML, flipbook :Boolean) :LayerMold {
        const layer :LayerMold = new LayerMold();
        layer.name = XmlUtil.getStringAttr(xml, NAME);
        layer.flipbook = flipbook;
		// mask
		if (mask!=null) layer.mask = mask;
        const location :String = baseLocation + ":" + layer.name;
        var frameXmlList :XMLList = xml.frames.DOMFrame;
        for each (var frameXml :XML in frameXmlList) {
            layer.keyframes.push(XflKeyframe.parse(lib, location, frameXml, flipbook));
        }
        if (layer.keyframes.length == 0) lib.addError(location, ParseError.INFO, "No keyframes on layer");

        var ii :int;
        var kf :KeyframeMold;
        var nextKf :KeyframeMold;

        // normalize skews, so that we always skew the shortest distance between
        // two angles (we don't want to skew more than Math.PI)
        for (ii = 0; ii < layer.keyframes.length - 1; ++ii) {
            kf = layer.keyframes[ii];
            nextKf = layer.keyframes[ii+1];
            frameXml = frameXmlList[ii];

            if (kf.skewX + Math.PI < nextKf.skewX) {
                nextKf.skewX += -Math.PI * 2;
            } else if (kf.skewX - Math.PI > nextKf.skewX) {
                nextKf.skewX += Math.PI * 2;
            }
            if (kf.skewY + Math.PI < nextKf.skewY) {
                nextKf.skewY += -Math.PI * 2;
            } else if (kf.skewY - Math.PI > nextKf.skewY) {
                nextKf.skewY += Math.PI * 2;
            }
        }

        // apply additional rotations
        var additionalRotation :Number = 0;
        for (ii = 0; ii < layer.keyframes.length - 1; ++ii) {
            kf = layer.keyframes[ii];
            nextKf = layer.keyframes[ii+1];
            frameXml = frameXmlList[ii];

            var motionTweenRotate :String = XmlUtil.getStringAttr(frameXml,
                XflKeyframe.MOTION_TWEEN_ROTATE, XflKeyframe.MOTION_TWEEN_ROTATE_NONE);

            // If a direction is specified, take it into account
            if (motionTweenRotate != XflKeyframe.MOTION_TWEEN_ROTATE_NONE) {
                var direction :Number = (motionTweenRotate == XflKeyframe.MOTION_TWEEN_ROTATE_CLOCKWISE ? 1 : -1);
                // negative scales affect rotation direction
                direction *= sign(nextKf.scaleX) * sign(nextKf.scaleY);

                while (direction < 0 && kf.skewX < nextKf.skewX) {
                    nextKf.skewX -= Math.PI * 2;
                }
                while (direction > 0 && kf.skewX > nextKf.skewX) {
                    nextKf.skewX += Math.PI * 2;
                }
                while (direction < 0 && kf.skewY < nextKf.skewY) {
                    nextKf.skewY -= Math.PI * 2;
                }
                while (direction > 0 && kf.skewY > nextKf.skewY) {
                    nextKf.skewY += Math.PI * 2;
                }

                // additional rotations specified?
                var motionTweenRotateTimes :Number =
                    XmlUtil.getNumberAttr(frameXml, XflKeyframe.MOTION_TWEEN_ROTATE_TIMES, 0);
                var thisRotation :Number = motionTweenRotateTimes * Math.PI * 2 * direction;
                additionalRotation += thisRotation;
            }

            nextKf.rotate(additionalRotation);
        }

        return layer;
    }

    protected static function sign (n :Number) :Number {
        return (n > 0 ? 1 : (n < 0 ? -1 : 0));
    }
}
}
