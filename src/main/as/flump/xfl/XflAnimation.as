//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import com.threerings.util.Log;
import com.threerings.util.Set;
import com.threerings.util.XmlUtil;

public class XflAnimation extends XflTopLevelComponent
{
    use namespace xflns;

    public var md5 :String;
    public var name :String;
    public var symbol :String;
    public var layers :Array;

    public function XflAnimation (baseLocation :String, xml :XML, md5 :String) {
        name = XmlUtil.getStringAttr(xml, "name");
        super(baseLocation + ":" + name);
        this.md5 = md5;
        symbol = XmlUtil.getStringAttr(xml, "linkageClassName");

        layers = XmlUtil.map(xml.timeline.DOMTimeline[0].layers.DOMLayer,
            function (layerEl :XML) :XflLayer {
                return new XflLayer(location, layerEl, _errors);
            });
        log.info("Got animation", "name", name, "layers", layers);
    }

    public function checkSymbols (lookup :Set) :void {
        for each (var layer :XflLayer in layers) layer.checkSymbols(lookup);
    }

    private static const log :Log = Log.getLog(XflAnimation);
}
}
