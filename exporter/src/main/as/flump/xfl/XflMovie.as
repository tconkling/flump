//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flump.display.Movie;
import flump.mold.KeyframeMold;
import flump.mold.MovieMold;

import com.threerings.util.XmlUtil;

public class XflMovie
{
    use namespace xflns;

    public static function parse (lib :XflLibrary, xml :XML) :MovieMold {
        const movie :MovieMold = new MovieMold();
        const name :String = XmlUtil.getStringAttr(xml, "name")
        const symbol :String = XmlUtil.getStringAttr(xml, "linkageClassName", null);
        movie.id = lib.createId(movie, name, symbol);
        const location :String = lib.location + ":" + movie.id;

        const layerEls :XMLList = xml.timeline.DOMTimeline[0].layers.DOMLayer;
        if (XmlUtil.getStringAttr(layerEls[0], "name") == "flipbook") {
            movie.layers.push(XflLayer.parse(lib, location, layerEls[0], true));
            if (symbol == null) {
                lib.addError(location, ParseError.CRIT, "Flipbook movie '" + movie.id + "' not exported");
            }
            for each (var kf :KeyframeMold in movie.layers[0].keyframes) {
                kf.ref = movie.id + "_flipbook_" + kf.index;

            }
        } else {
            for each (var layerEl :XML in layerEls) {
                if (XmlUtil.getStringAttr(layerEl, "layerType", "") != "guide") {
                    movie.layers.unshift(XflLayer.parse(lib, location, layerEl, false));
                }
            }
        }
        movie.fillLabels();

        if (movie.layers.length == 0) {
            lib.addError(location, ParseError.CRIT, "Movies must have at least one layer");
        }

        return movie;
    }
}
}
