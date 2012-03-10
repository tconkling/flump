//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

public class XflTexture extends XflTopLevelComponent
{
    public var libraryItem :String;
    public var symbol :String;

    public function XflTexture (location :String, xml :XML) {
        const converter :XmlConverter = new XmlConverter(xml);
        libraryItem = converter.getStringAttr("name");
        super(location + ":" + libraryItem);
        symbol = converter.getStringAttr("linkageClassName");
    }
}
}
