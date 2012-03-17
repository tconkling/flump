//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

public class XflTexture
{
    public var libraryItem :String;
    public var symbol :String;

    // The hash of the XML file for this symbol in the library
    public var md5 :String;

    public var location :String;

    public function XflTexture (location :String, xml :XML, md5 :String) {
        const converter :XmlConverter = new XmlConverter(xml);
        libraryItem = converter.getStringAttr("name");
        this.location = location + ":" + libraryItem;
        this.md5 = md5;
        symbol = converter.getStringAttr("linkageClassName");
    }
}
}
