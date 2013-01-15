//
// Flump - Copyright 2013 Flump Authors

package flump.mold {

/** @private */
public class AtlasMold
{
    public var file :String;
    public var textures :Vector.<AtlasTextureMold> = new <AtlasTextureMold>[];

    public static function scaleFactorSuffix (scaleFactor :int) :String {
        return (scaleFactor == 1 ? "" : "@" + scaleFactor + "x");
    }

    public static function extractScaleFactor (filename :String) :int {
        var result :Object = SCALE_FACTOR.exec(Files.stripPathAndDotSuffix(filename));
        return (result != null ? int(result[1]) : 1);
    }

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

    public function get scaleFactor () :int {
        return extractScaleFactor(file);
    }

    protected static const SCALE_FACTOR :RegExp = /@(\d+)x$/;
}
}
