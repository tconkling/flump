//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

public class XflTexture extends XflTopLevelComponent
{
    public var md5 :String;
    public var name :String;
    public var symbol :String;

    public function XflTexture (location :String, xml :XML, md5 :String) {
        const converter :XmlConverter = new XmlConverter(xml);
        name = converter.getStringAttr("name");
        super(location + ":" + name);
        this.md5 = md5;
        symbol = converter.getStringAttr("linkageClassName");
    }
}
}
