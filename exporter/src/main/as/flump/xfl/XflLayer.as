//
// Flump - Copyright 2013 Flump Authors

package flump.xfl {

import com.threerings.util.XmlUtil;

import flump.mold.KeyframeMold;
import flump.mold.LayerMold;

public class XflLayer
{
    use namespace xflns;
    
    public static function parse (lib :XflLibrary, baseLocation :String, xml :XML, flipbook :Boolean) :LayerMold {
        const layer :LayerMold = new LayerMold();
        layer.name = XmlUtil.getStringAttr(xml, "name");
        layer.flipbook = flipbook;
        const location :String = baseLocation + ":" + layer.name;
        for each (var frameEl :XML in xml.frames.DOMFrame) {
            layer.keyframes.push(XflKeyframe.parse(lib, location, frameEl, flipbook));
        }
        if (layer.keyframes.length == 0) lib.addError(location, ParseError.INFO, "No keyframes on layer");
        
        var domFrames :XMLList = xml.frames.DOMFrame;
        var ii :int;
        var kf :KeyframeMold;
        var nextKf :KeyframeMold;
        
        // normalize skews, so that we always skew the shortest distance between
        // two angles (we don't want to skew more than Math.PI)
        for (ii = 0; ii < layer.keyframes.length - 1; ++ii) {
            kf = layer.keyframes[ii];
            nextKf = layer.keyframes[ii+1];
            frameEl = domFrames[ii];
            
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
            frameEl = domFrames[ii];
            
            var motionTweenRotate :String =
                XmlUtil.getStringAttr(frameEl, "motionTweenRotate", "none");
            
            // If a direction is specified, take it into account
            if (motionTweenRotate != "none") {
                var direction :Number = (motionTweenRotate == "clockwise" ? 1 : -1);
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
                    XmlUtil.getNumberAttr(frameEl, "motionTweenRotateTimes", 0);
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
