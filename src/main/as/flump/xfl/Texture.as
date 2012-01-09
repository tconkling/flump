//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import com.threerings.util.XmlUtil;

public class Texture
{
    public var name :String;
    public var symbol :String;


    public function Texture (xml :XML) {
        name = XmlUtil.getStringAttr(xml, "name");
        symbol = XmlUtil.getStringAttr(xml, "linkageClassName");
    }
}
}
