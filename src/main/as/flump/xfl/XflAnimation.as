//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import com.threerings.util.F;
import com.threerings.util.Log;
import com.threerings.util.XmlUtil;

public class XflAnimation
{
    use namespace xflns;

    public var md5 :String;
    public var name :String;
    public var symbol :String;
    public var layers :Array;

    public function XflAnimation (xml :XML, md5 :String) {
        this.md5 = md5;
        name = XmlUtil.getStringAttr(xml, "name");
        symbol = XmlUtil.getStringAttr(xml, "linkageClassName");

        layers = XmlUtil.map(xml.timeline.DOMTimeline[0].layers.DOMLayer, F.constructor(XflLayer));
        log.info("Got animation", "name", name, "layers", layers);
    }

    private static const log :Log = Log.getLog(XflAnimation);
}
}
