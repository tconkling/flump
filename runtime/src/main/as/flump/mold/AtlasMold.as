//
// Flump - Copyright 2012 Three Rings Design

package flump.mold {

/** @private */
public class AtlasMold
{
    public var file :String;
    public var textures :Vector.<AtlasTextureMold> = new Vector.<AtlasTextureMold>();

    public static function fromJSON (o :Object) :AtlasMold {
        const mold :AtlasMold = new AtlasMold();
        mold.file = require(o, "file");
        for each (var tex :Object in require(o, "textures")) {
            mold.textures.push(AtlasTextureMold.fromJSON(tex));
        }
        return mold;
    }

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
