//
// Flump - Copyright 2013 Flump Authors

package flump.xfl {

import aspire.util.XmlUtil;

import flump.SwfTexture;
import flump.executor.load.LoadedSwf;

public class XflTexture
{
    public var symbol :String;

    public function XflTexture (lib :XflLibrary, location :String, xml :XML) {
        symbol = XmlUtil.getStringAttr(xml, "linkageClassName");
        lib.createId(this, XmlUtil.getStringAttr(xml, "name"), symbol);
    }

    public function isValid (swf :LoadedSwf) :Boolean {
        var swfTex :SwfTexture = SwfTexture.fromTexture(swf, this);
        return (swfTex.w > 0 && swfTex.h > 0);
    }
}
}
