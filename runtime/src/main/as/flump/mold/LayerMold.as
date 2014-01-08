//
// Flump - Copyright 2013 Flump Authors

package flump.mold {

/** @private */
public class LayerMold
{
    public var name :String;
    public var keyframes :Vector.<KeyframeMold> = new <KeyframeMold>[];
    public var flipbook :Boolean;

    public static function fromJSON (o :Object) :LayerMold {
        const mold :LayerMold = new LayerMold();
        mold.name = require(o, "name");
        for each (var kf :Object in require(o, "keyframes")) {
            mold.keyframes.push(KeyframeMold.fromJSON(kf));
        }
        mold.flipbook = o.hasOwnProperty("flipbook");
        return mold;
    }

    public function keyframeForFrame (frame :int) :KeyframeMold {
        var ii :int = 1;
        for (; ii < keyframes.length && keyframes[ii].index <= frame; ii++) {}
        return keyframes[ii - 1];
    }

    public function get frames () :int {
        if (keyframes.length == 0) return 0;
        const lastKf :KeyframeMold = keyframes[keyframes.length - 1];
        return lastKf.index + lastKf.duration;
    }

    public function toJSON (_:*) :Object {
        var json :Object = {
            name: name,
            keyframes: keyframes
        };
        if (flipbook) json.flipbook = flipbook;
        return json;
    }

    public function toXML () :XML {
        var xml :XML = <layer name={name}/>;
        if (flipbook) xml.@flipbook = flipbook;
        for each (var kf :KeyframeMold in keyframes) xml.appendChild(kf.toXML());
        return xml;
    }
}
}
