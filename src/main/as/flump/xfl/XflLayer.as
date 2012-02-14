//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flump.ParseError;
import flump.ParseErrorSeverity;

import com.threerings.util.F;
import com.threerings.util.Set;
import com.threerings.util.XmlUtil;

public class XflLayer extends XflComponent
{
    use namespace xflns;

    public var name :String;
    public var keyframes :Array;
    public var libraryName :String;

    public function XflLayer (baseLocation :String, xml :XML, errors :Vector.<ParseError>) {
        name = XmlUtil.getStringAttr(xml, "name");
        super(baseLocation + ":" + name, errors);
        keyframes = XmlUtil.map(xml.frames.DOMFrame, function (frameEl :XML) :XflKeyframe {
            return new XflKeyframe(location, frameEl, _errors);
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
