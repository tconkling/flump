//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flump.mold.KeyframeMold;
import flump.mold.LayerMold;
import flump.mold.MovieMold;

import com.threerings.util.XmlUtil;

public class XflMovie
{
    use namespace xflns;

    public static function parse (lib :XflLibrary, xml :XML, md5 :String) :MovieMold {
        const movie :MovieMold = new MovieMold();
        movie.libraryItem = XmlUtil.getStringAttr(xml, "name");
        movie.location = lib.location + ":" + movie.libraryItem;
        movie.md5 = md5;
        movie.symbol = XmlUtil.getStringAttr(xml, "linkageClassName", null);

        const layerEls :XMLList = xml.timeline.DOMTimeline[0].layers.DOMLayer;
        if (XmlUtil.getStringAttr(layerEls[0], "name") == "flipbook") {
            movie.layers.push(XflLayer.parse(lib, movie.location, layerEls[0], true));
            if (movie.symbol == null) {
                lib.addError(movie, ParseError.CRIT, "Flipbook movie '" + movie.libraryItem + "' not exported");
            }
            for each (var kf :KeyframeMold in movie.layers[0].keyframes) {
                kf.id = movie.libraryItem + "_flipbook_" + kf.index;

            }
        } else {
            for each (var layerEl :XML in layerEls) {
                if (XmlUtil.getStringAttr(layerEl, "layerType", "") != "guide") {
                    movie.layers.unshift(XflLayer.parse(lib, movie.location, layerEl, false));
                }
            }
        }
        movie.labels = new Vector.<Vector.<String>>(movie.frames, true);
        for each (var layer :LayerMold in movie.layers) {
            for each (kf in layer.keyframes) {
                if (kf.label != null) {
                    var frameLabels :Vector.<String> = movie.labels[kf.index];
                    if (frameLabels == null) {
                        frameLabels = new Vector.<String>();
                        movie.labels[kf.index] = frameLabels;
                    }
                    frameLabels.push(kf.label);
                }
            }
        }
        return movie;
    }
}
}
