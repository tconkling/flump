//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

public class XflTexture extends XflTopLevelComponent
{
    public var md5 :String;
    public var libraryItem :String;
    public var symbol :String;

    public function XflTexture (location :String, xml :XML, md5 :String) {
        const converter :XmlConverter = new XmlConverter(xml);
        libraryItem = converter.getStringAttr("name");
        super(location + ":" + libraryItem);
        this.md5 = md5;
        symbol = converter.getStringAttr("linkageClassName");
    }
}
}
