//
// flump-runtime

package flump.mold {

public class TextureGroupMold
{
    public var scaleFactor :int;
    public var atlases :Vector.<AtlasMold> = new <AtlasMold>[];

    public static function fromJSON (o :Object) :TextureGroupMold {
        const mold :TextureGroupMold = new TextureGroupMold();
        mold.scaleFactor = require(o, "scaleFactor");
        for each (var atlas :Object in require(o, "atlases")) {
            mold.atlases.push(AtlasMold.fromJSON(atlas));
        }
        return mold;
    }

    public function toJSON (_:*) :Object {
        return {
            scaleFactor: scaleFactor,
            atlases: atlases
        };
    }

    public function toXML () :XML {
        var xml :XML = <textureGroup scaleFactor={scaleFactor}/>;
        for each (var atlas :AtlasMold in atlases) {
            xml.appendChild(atlas.toXML());
        }
        return xml;
    }
}
}
