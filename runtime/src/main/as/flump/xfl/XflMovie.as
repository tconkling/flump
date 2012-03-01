//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flash.utils.Dictionary;

public class XflMovie extends XflTopLevelComponent
{
    use namespace xflns;

    public var md5 :String;
    public var libraryItem :String;
    public var symbol :String;
    public var layers :Array;

    public function XflMovie (baseLocation :String, xml :XML, md5 :String) {
        const converter :XmlConverter = new XmlConverter(xml);
        libraryItem = converter.getStringAttr("name");
        super(baseLocation + ":" + libraryItem);
        this.md5 = md5;
        symbol = converter.getStringAttr("linkageClassName", null);

        const layerEls :XMLList = xml.timeline.DOMTimeline[0].layers.DOMLayer;
        if (new XmlConverter(layerEls[0]).getStringAttr("name") == "flipbook") {
            layers = [new XflLayer(location, layerEls[0], _errors, true)];
            if (symbol == null) {
                addError(ParseError.CRIT, "Flipbook movie '" + libraryItem + "' not exported");
            }
        } else {
            layers = new Array();
            for each (var layerEl :XML in layerEls) {
                if (new XmlConverter(layerEl).getStringAttr("layerType", "") != "guide") {
                    layers.unshift(new XflLayer(location, layerEl, _errors, false));
                }
            }
        }
    }

    public function checkSymbols (lookup :Dictionary) :void {
        if (flipbook && !lookup.hasOwnProperty(symbol)) {
            addError(ParseError.CRIT, "Flipbook movie '" + symbol + "' not exported");
        } else for each (var layer :XflLayer in layers) layer.checkSymbols(lookup);
    }

    public function get flipbook () :Boolean { return layers[0].flipbook; }
}
}
