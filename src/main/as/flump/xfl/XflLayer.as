//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flash.utils.Dictionary;

import com.threerings.util.F;
import com.threerings.util.XmlUtil;

public class XflLayer extends XflComponent
{
    use namespace xflns;

    public var name :String;
    public const keyframes :Vector.<XflKeyframe> = new Vector.<XflKeyframe>();
    public var flipbook :Boolean;

    public function XflLayer (baseLocation :String, xml :XML, errors :Vector.<ParseError>,
        flipbook :Boolean) {
        name = XmlUtil.getStringAttr(xml, "name");
        this.flipbook = flipbook;
        super(baseLocation + ":" + name, errors);
        for each (var frameEl :XML in xml.frames.DOMFrame) {
            keyframes.push(new XflKeyframe(location, frameEl, _errors, flipbook));
        }
        if (keyframes.length == 0) addError(ParseErrorSeverity.INFO, "No keyframes on layer");
    }

    public function keyframeForFrame (frame :int) :XflKeyframe {
        for (var ii :int = 1; ii < keyframes.length; ii++) {
            if (keyframes[ii].index > frame) return keyframes[ii - 1];
        }
        return keyframes[keyframes.length - 1];
    }


    public function checkSymbols (symbols :Dictionary) :void {
        for each (var kf :XflKeyframe in keyframes) kf.checkSymbols(symbols);
    }
}
}
