//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import com.threerings.util.F;
import com.threerings.util.XmlUtil;

public class Layer
{
    use namespace xflns;

    public var name :String;
    public var keyframes :Array;

    public function Layer (xml :XML) {
        name = XmlUtil.getStringAttr(xml, "name");
        keyframes = XmlUtil.map(xml.frames.DOMFrame, F.constructor(Keyframe));
    }
}
}
