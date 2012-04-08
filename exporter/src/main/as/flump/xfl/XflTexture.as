//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import com.threerings.util.XmlUtil;

import flump.mold.Mold;

public class XflTexture extends Mold
{
    public var libraryItem :String;
    public var symbol :String;

    // The hash of the XML file for this symbol in the library
    public var md5 :String;

    public function XflTexture (lib :XflLibrary, location :String, xml :XML, md5 :String) {
        libraryItem = XmlUtil.getStringAttr(xml, "name");
        this.location = location + ":" + libraryItem;
        this.md5 = md5;
        symbol = XmlUtil.getStringAttr(xml, "linkageClassName");

        if (symbol != null && symbol != libraryItem) {
            lib.addError(this, ParseError.CRIT,
                "export name doesn't match library name (" +
                symbol + ", " + libraryItem + ")");
        }
    }
}
}
