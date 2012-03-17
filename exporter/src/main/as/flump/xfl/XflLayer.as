//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flump.mold.LayerMold;
import flump.mold.ParseError;

public class XflLayer extends LayerMold
{
    use namespace xflns;

    public function XflLayer (baseLocation :String, xml :XML, errors :Vector.<ParseError>,
        flipbook :Boolean) {
        super(errors);
        name = new XmlConverter(xml).getStringAttr("name");
        this.flipbook = flipbook;
        location = baseLocation + ":" + name
        for each (var frameEl :XML in xml.frames.DOMFrame) {
            keyframes.push(new XflKeyframe(location, frameEl, _errors, flipbook));
        }
        if (keyframes.length == 0) addError(ParseError.INFO, "No keyframes on layer");
    }

}
}
