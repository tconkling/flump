//
// Flump - Copyright 2012 Three Rings Design

package flump.mold {

import flash.net.registerClassAlias;

public class LayerMold extends Mold
{
    // Make this come out as itself in AMF
    registerClassAlias("LayerMold", LayerMold);

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
        if (flipbook) {
            json.flipbook = flipbook;
        }
        return json;
    }

    public function toXML () :XML
    {
        var xml :XML = <layer name={name}/>
            if (flipbook) {
                xml.@flipbook = flipbook;
            }

        for each (var kf :KeyframeMold in keyframes) {
            xml.appendChild(kf.toXML());
        }
        return xml;
    }
}
}
