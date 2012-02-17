//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flash.filesystem.File;

import com.threerings.util.XmlUtil;

public class XflTexture extends XflTopLevelComponent
{
    public var md5 :String;
    public var name :String;
    public var symbol :String;

    public function XflTexture (location :String, xml :XML, md5 :String) {
        name = XmlUtil.getStringAttr(xml, "name");
        super(location + ":" + name);
        this.md5 = md5;
        symbol = XmlUtil.getStringAttr(xml, "linkageClassName");
    }

    public function exportPath (base :File) :File { return base.resolvePath(symbol + '.png') }

}
}
