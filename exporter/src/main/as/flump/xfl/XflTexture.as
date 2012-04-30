//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import com.threerings.util.XmlUtil;

import flump.SwfTexture;
import flump.executor.load.LoadedSwf;

public class XflTexture
{
    public var symbol :String;

    // The hash of the XML file for this symbol in the library
    public var md5 :String;

    public function XflTexture (lib :XflLibrary, location :String, xml :XML, md5 :String) {
        this.md5 = md5;
        symbol = XmlUtil.getStringAttr(xml, "linkageClassName");
        lib.createId(this, XmlUtil.getStringAttr(xml, "name"), symbol);
    }

    public function isValid (swf :LoadedSwf) :Boolean
    {
        var swfTex :SwfTexture = SwfTexture.fromTexture(swf, this);
        return (swfTex.w > 0 && swfTex.h > 0);
    }
}
}
