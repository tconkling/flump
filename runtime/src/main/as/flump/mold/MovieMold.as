//
// Flump - Copyright 2012 Three Rings Design

package flump.mold {

public class MovieMold extends Mold
{
    public var libraryItem :String;
    public var symbol :String;
    public var layers :Vector.<LayerMold> = new Vector.<LayerMold>();
    public var labels :Vector.<Vector.<String>>;

    // The hash of the XML file for this symbol in the library
    public var md5 :String;

    public function get frames () :int {
        var frames :int = 0;
        for each (var layer :LayerMold in layers) frames = Math.max(frames, layer.frames);
        return frames;
    }

    public function get flipbook () :Boolean { return layers[0].flipbook; }

    public function toJSON (_:*) :Object {
        return {
            libraryItem: libraryItem,
            symbol: symbol,
            layers: layers,
            md5: md5
        };
    }

    public static function fromJSON (o :Object) :MovieMold {
        const mold :MovieMold = new MovieMold();
        mold.libraryItem = require(o, "libraryItem");
        mold.symbol = require(o, "symbol");
        for each (var layer :Object in require(o, "layers")) mold.layers.push(LayerMold.fromJSON(layer));
        mold.md5 = require(o, "md5");
        return mold;
    }

    public function toXML () :XML {
        var xml :XML = <movie
            name={symbol}
            md5={md5}
        />;
        for each (var layer :LayerMold in layers) {
            xml.appendChild(layer.toXML());
        }
        return xml;
    }

}
}
