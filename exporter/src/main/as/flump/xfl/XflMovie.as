//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flump.mold.KeyframeMold;
import flump.mold.MovieMold;

public class XflMovie
{
    use namespace xflns;

    public static function parse (lib :XflLibrary, xml :XML, md5 :String) :MovieMold {
        const converter :XmlConverter = new XmlConverter(xml);
        const movie :MovieMold = new MovieMold();
        movie.libraryItem = converter.getStringAttr("name");
        movie.location = lib.location + ":" + movie.libraryItem;
        movie.md5 = md5;
        movie.symbol = converter.getStringAttr("linkageClassName", null);

        const layerEls :XMLList = xml.timeline.DOMTimeline[0].layers.DOMLayer;
        if (new XmlConverter(layerEls[0]).getStringAttr("name") == "flipbook") {
            movie.layers.push(XflLayer.parse(lib, movie.location, layerEls[0], true));
            if (movie.symbol == null) {
                lib.addError(movie, ParseError.CRIT, "Flipbook movie '" + movie.libraryItem + "' not exported");
            }
            for each (var kf :KeyframeMold in movie.layers[0].keyframes) {
                kf.id = movie.libraryItem + "_flipbook_" + kf.index;

            }
        } else {
            for each (var layerEl :XML in layerEls) {
                if (new XmlConverter(layerEl).getStringAttr("layerType", "") != "guide") {
                    movie.layers.unshift(XflLayer.parse(lib, movie.location, layerEl, false));
                }
            }
        }
        return movie;
    }
}
}
