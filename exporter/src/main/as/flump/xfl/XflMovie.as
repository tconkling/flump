//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flump.mold.MovieMold;
import flump.mold.ParseError;

public class XflMovie extends MovieMold
{
    use namespace xflns;

    public function XflMovie (baseLocation :String, xml :XML, md5 :String) {
        const converter :XmlConverter = new XmlConverter(xml);
        libraryItem = converter.getStringAttr("name");
        location = baseLocation + ":" + libraryItem;
        this.md5 = md5;
        symbol = converter.getStringAttr("linkageClassName", null);

        const layerEls :XMLList = xml.timeline.DOMTimeline[0].layers.DOMLayer;
        if (new XmlConverter(layerEls[0]).getStringAttr("name") == "flipbook") {
            layers.push(new XflLayer(location, layerEls[0], _errors, true));
            if (symbol == null) {
                addError(ParseError.CRIT, "Flipbook movie '" + libraryItem + "' not exported");
            }
            for each (var kf :XflKeyframe in layers[0].keyframes) {
                kf.id = libraryItem + "_flipbook_" + kf.index;

            }
        } else {
            for each (var layerEl :XML in layerEls) {
                if (new XmlConverter(layerEl).getStringAttr("layerType", "") != "guide") {
                    layers.unshift(new XflLayer(location, layerEl, _errors, false));
                }
            }
        }
    }
}
}
