//
// Flump - Copyright 2012 Three Rings Design

package flump.mold {

import flump.display.Movie;

/** @private */
public class MovieMold
{
    public var id :String;
    public var layers :Vector.<LayerMold> = new Vector.<LayerMold>();
    public var labels :Vector.<Vector.<String>>;

    public static function fromJSON (o :Object) :MovieMold {
        const mold :MovieMold = new MovieMold();
        mold.id = require(o, "id");
        for each (var layer :Object in require(o, "layers")) mold.layers.push(LayerMold.fromJSON(layer));
        return mold;
    }

    public function get frames () :int {
        var frames :int = 0;
        for each (var layer :LayerMold in layers) frames = Math.max(frames, layer.frames);
        return frames;
    }

    public function get flipbook () :Boolean { return (layers.length > 0 && layers[0].flipbook); }

    public function fillLabels () :void {
        labels = new Vector.<Vector.<String>>(frames, true);
        if (labels.length == 0) {
            return;
        }
        labels[0] = new Vector.<String>();
        labels[0].push(Movie.FIRST_FRAME);
        labels[frames - 1] = new Vector.<String>();
        labels[frames - 1].push(Movie.LAST_FRAME);
        for each (var layer :LayerMold in layers) {
            for each (var kf :KeyframeMold in layer.keyframes) {
                if (kf.label == null) continue;
                if (labels[kf.index] == null) labels[kf.index] = new Vector.<String>();
                labels[kf.index].push(kf.label);
            }

        }
    }

    public function scale (scale :Number) :MovieMold {
        const clone :MovieMold = fromJSON(JSON.parse(JSON.stringify(this)));
        for each (var layer :LayerMold in clone.layers) {
            for each (var kf :KeyframeMold in layer.keyframes) {
                kf.x *= scale;
                kf.y *= scale;
                kf.pivotX *= scale;
                kf.pivotY *= scale;
            }
        }
        return clone;
    }

    public function toJSON (_:*) :Object {
        const json :Object = {
            id: id,
            layers: layers
        };
        return json
    }

    public function toXML () :XML {
        var xml :XML = <movie name={id}/>;
        for each (var layer :LayerMold in layers) xml.appendChild(layer.toXML());
        return xml;
    }

}
}
