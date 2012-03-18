//
// Flump - Copyright 2012 Three Rings Design

package flump.mold {

import flash.net.registerClassAlias;

public class AtlasMold
{
    // Make this come out as itself in AMF
    registerClassAlias("AtlasMold", AtlasMold);

    public var file :String;
    public var textures :Vector.<AtlasTextureMold> = new Vector.<AtlasTextureMold>();

    public function toJSON (_:*) :Object {
        return {
            file: file,
            textures: textures
        };
    }

    public function toXML () :XML {
        var xml :XML = <atlas file={file} />;
        for each (var tex :AtlasTextureMold in textures) xml.appendChild(tex.toXML());
        return xml;
    }

}
}
