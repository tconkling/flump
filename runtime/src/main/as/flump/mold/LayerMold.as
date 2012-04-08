//
// Flump - Copyright 2012 Three Rings Design

package flump.mold {

public class LayerMold
{
    public var name :String;
    public var keyframes :Vector.<KeyframeMold> = new Vector.<KeyframeMold>();
    public var flipbook :Boolean;

    public function keyframeForFrame (frame :int) :KeyframeMold {
        var ii :int = 1;
        for (; ii < keyframes.length && keyframes[ii].index <= frame; ii++) {}
        return keyframes[ii - 1];
    }

    public function get frames () :int {
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

    public static function fromJSON (o :Object) :LayerMold {
        const mold :LayerMold = new LayerMold();
        mold.name = require(o, "name");
        for each (var kf :Object in require(o, "keyframes")) mold.keyframes.push(KeyframeMold.fromJSON(kf));
        mold.flipbook = o.hasOwnProperty("flipbook");
        return mold;
    }

    public function toXML () :XML
    {
        var xml :XML = <layer name={name}/>
        if (flipbook) xml.@flipbook = flipbook;
        for each (var kf :KeyframeMold in keyframes) xml.appendChild(kf.toXML());
        return xml;
    }
}
}
