//
// Flump - Copyright 2013 Flump Authors

package flump.mold {

public class LayerMold
{
    public var name :String;
    public var mask :String;
    public var isMask :Boolean;
    public var keyframes :Vector.<KeyframeMold> = new <KeyframeMold>[];
    public var flipbook :Boolean;
    public var baseScale:Number;

    public static function fromJSON (o :Object) :LayerMold {
        const mold :LayerMold = new LayerMold();
        mold.name = require(o, "name");
        mold.baseScale = o["baseScale"] != null ? o["baseScale"] : 1;
        for each (var kf :Object in require(o, "keyframes")) {
            kf["baseScale"] = mold.baseScale;
            mold.keyframes.push(KeyframeMold.fromJSON(kf));
        }
        mold.flipbook = o.hasOwnProperty("flipbook");
        mold.isMask = o.hasOwnProperty("isMask");
        mold.mask = o["mask"] != null ? o["mask"] : null;
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
        if (mask) json.mask = mask;
        if (isMask) json.isMask = isMask;
        return json;
    }

    public function toXML () :XML {
        var xml :XML = <layer name={name}/>;
        if (flipbook) xml.@flipbook = flipbook;
        if (mask) xml.@mask = mask;
        if (isMask) xml.@isMask = isMask;
        for each (var kf :KeyframeMold in keyframes) xml.appendChild(kf.toXML());
        return xml;
    }
}
}
