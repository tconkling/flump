//
// Flump - Copyright 2013 Flump Authors

package flump.mold {

/** @private */
public class LibraryMold
{
    // The frame rate of movies in this library
    public var frameRate :Number;

    // The MD5 of the published library SWF
    public var md5 :String;

    // the format of the atlases. Default is "png"
    public var textureFormat :String;

    public var movies :Vector.<MovieMold> = new <MovieMold>[];

    public var textureGroups :Vector.<TextureGroupMold> = new <TextureGroupMold>[];

    public static function fromJSON (o :Object) :LibraryMold {
        const mold :LibraryMold = new LibraryMold();
        mold.frameRate = require(o, "frameRate");
        mold.md5 = require(o, "md5");
        mold.textureFormat = o["textureFormat"] || "png";
        for each (var movie :Object in require(o, "movies")) mold.movies.push(MovieMold.fromJSON(movie));
        for each (var tg :Object in require(o, "textureGroups")) mold.textureGroups.push(TextureGroupMold.fromJSON(tg));
        return mold;
    }

    public function toJSON (_:*) :Object {
        return {
            frameRate: frameRate,
            md5: md5,
            movies: movies,
            textureGroups: textureGroups
        };
    }

    public function bestTextureGroupForScaleFactor (scaleFactor :int) :TextureGroupMold {
        if (textureGroups.length == 0) {
            return null;
        }

        // sort by scale factor
        textureGroups.sort(function (a :TextureGroupMold, b :TextureGroupMold) :int {
            return compareInts(a.scaleFactor, b.scaleFactor);
        });

        // find the group with the highest scale factor <= our desired scale factor, if one exists
        for (var ii :int = textureGroups.length - 1; ii >= 0; --ii) {
            if (textureGroups[ii].scaleFactor <= scaleFactor) {
                return textureGroups[ii];
            }
        }

        // return the group with the smallest scale factor
        return textureGroups[0];
    }

    protected static function compareInts (a :int, b :int) :int {
        return (a > b) ? 1 : (a == b ? 0 : -1);
    }
}
}
