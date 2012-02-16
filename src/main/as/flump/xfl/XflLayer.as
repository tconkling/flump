//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import com.threerings.util.F;
import com.threerings.util.Set;
import com.threerings.util.XmlUtil;

public class XflLayer extends XflComponent
{
    use namespace xflns;

    public var name :String;
    public var keyframes :Array;
    public var flipbook :Boolean;

    public function XflLayer (baseLocation :String, xml :XML, errors :Vector.<ParseError>,
        flipbook :Boolean) {
        name = XmlUtil.getStringAttr(xml, "name");
        this.flipbook = flipbook;
        super(baseLocation + ":" + name, errors);
        keyframes = XmlUtil.map(xml.frames.DOMFrame, function (frameEl :XML) :XflKeyframe {
            return new XflKeyframe(location, frameEl, _errors, flipbook);
        });
        if (keyframes.length == 0) addError(ParseErrorSeverity.INFO, "No keyframes on layer");
    }

    public function checkSymbols (symbols :Set) :void {
        for each (var kf :XflKeyframe in keyframes) kf.checkSymbols(symbols);
    }
}
}
