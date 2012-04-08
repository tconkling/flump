//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flump.LibraryElement;

import com.threerings.util.XmlUtil;

public class XflTexture extends LibraryElement
{
    public var symbol :String;

    // The hash of the XML file for this symbol in the library
    public var md5 :String;

    public function XflTexture (lib :XflLibrary, location :String, xml :XML, md5 :String) {
        this.md5 = md5;
        symbol = XmlUtil.getStringAttr(xml, "linkageClassName");
        this.location = location + ":" + symbol;
        lib.createId(this, XmlUtil.getStringAttr(xml, "name"), symbol);
    }
}
}
