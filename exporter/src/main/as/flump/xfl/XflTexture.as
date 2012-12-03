//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import executor.load.LoadedSwf;

import flump.SwfTexture;

import com.threerings.util.XmlUtil;

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
