//
// Flump - Copyright 2013 Flump Authors

package flump.xfl {

import aspire.util.XmlUtil;

import flump.SwfTexture;
import flump.executor.load.LoadedSwf;

public class XflTexture
{
    
    use namespace xflns;
    
    public var symbol :String;
    public var data :Object;
    public var baseClass :String;

    public function XflTexture (lib :XflLibrary, location :String, xml :XML) {
        symbol = XmlUtil.getStringAttr(xml, "linkageClassName");
        
        // persistent Data
        if (xml.persistentData!=null) {
            var lData:Object = XflCustomData.getCustomData(xml.persistentData);
            if (lData != null) data = lData;
        }
        
        
        // base Class
        var lBaseClass:String = XmlUtil.getStringAttr(xml, "linkageBaseClass", null);
        if (lBaseClass != "flash.display.Sprite") baseClass = lBaseClass;
        
        lib.createId(this, XmlUtil.getStringAttr(xml, "name"), symbol);
    }

    public function isValid (lib :XflLibrary) :Boolean {
        var swfTex :SwfTexture = SwfTexture.fromTexture(lib, this);
        return (swfTex.w > 0 && swfTex.h > 0);
    }
}
}
