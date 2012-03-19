//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flump.mold.LayerMold;

import com.threerings.util.XmlUtil;

public class XflLayer
{
    use namespace xflns;

    public static function parse (lib :XflLibrary, baseLocation :String, xml :XML, flipbook :Boolean) :LayerMold {
        const layer :LayerMold = new LayerMold();
        layer.name = XmlUtil.getStringAttr(xml, "name");
        layer.flipbook = flipbook;
        layer.location = baseLocation + ":" + layer.name
        for each (var frameEl :XML in xml.frames.DOMFrame) {
            layer.keyframes.push(XflKeyframe.parse(lib, layer.location, frameEl, flipbook));
        }
        if (layer.keyframes.length == 0) lib.addError(layer, ParseError.INFO, "No keyframes on layer");
        return layer;
    }

}
}
