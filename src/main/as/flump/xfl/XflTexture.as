//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flash.filesystem.File;

import com.threerings.util.XmlUtil;

public class XflTexture
{
    public var name :String;
    public var symbol :String;

    public function XflTexture (xml :XML) {
        name = XmlUtil.getStringAttr(xml, "name");
        symbol = XmlUtil.getStringAttr(xml, "linkageClassName");
    }

    public function exportPath (base :File) :File { return base.resolvePath(symbol + '.png') }
}
}
