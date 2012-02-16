//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import com.threerings.util.Log;
import com.threerings.util.Set;
import com.threerings.util.XmlUtil;

public class XflMovie extends XflTopLevelComponent
{
    use namespace xflns;

    public var md5 :String;
    public var name :String;
    public var symbol :String;
    public var layers :Array;

    public function XflMovie (baseLocation :String, xml :XML, md5 :String) {
        name = XmlUtil.getStringAttr(xml, "name");
        super(baseLocation + ":" + name);
        this.md5 = md5;
        symbol = XmlUtil.getStringAttr(xml, "linkageClassName");

        const layerEls :XMLList = xml.timeline.DOMTimeline[0].layers.DOMLayer;
        if (XmlUtil.getStringAttr(layerEls[0], "name") == "flipbook") {
            layers = [new XflLayer(location, layerEls[0], _errors, true)];
        } else {
            layers = XmlUtil.map(layerEls, function (layerEl :XML) :XflLayer {
                return new XflLayer(location, layerEl, _errors, false);
            });
        }
        log.info("Got movie", "name", name, "layers", layers);
    }

    public function checkSymbols (lookup :Set) :void {
        if (flipbook && !lookup.contains(symbol)) {
            addError(ParseErrorSeverity.CRIT, "Flipbook movie '" + symbol + "' not exported");
        } else for each (var layer :XflLayer in layers) layer.checkSymbols(lookup);
    }

    public function get flipbook () :Boolean { return layers[0].flipbook; }

    private static const log :Log = Log.getLog(XflMovie);
}
}
