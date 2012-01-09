//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import com.threerings.util.F;
import com.threerings.util.Log;
import com.threerings.util.XmlUtil;

public class Animation
{
    use namespace xflns;

    public var name :String;
    public var layers :Array;

    public function Animation (xml :XML) {
        name = XmlUtil.getStringAttr(xml, "name");

        layers = XmlUtil.map(xml.timeline.DOMTimeline[0].layers.DOMLayer, F.constructor(Layer));
        log.info("Got animation", "name", name, "layers", layers);
    }

    private static const log :Log = Log.getLog(Animation);
}
}
