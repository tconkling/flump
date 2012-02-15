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
    public var libraryName :String;
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
        else libraryName = keyframes[0].libraryName;
    }

    public function checkSymbols (symbols :Set) :void {
        if (libraryName != null && !symbols.contains(libraryName)) {
            addError(ParseErrorSeverity.CRIT, "Symbol '" + libraryName + "' not exported");
        }
    }
}
}
