//
// Flump - Copyright 2012 Three Rings Design

package flump.mold {

/** @private */
public class LibraryMold
{
    // The frame rate of movies in this library
    public var frameRate :Number;

    // The MD5 of the published library SWF
    public var md5 :String;

    public var movies :Vector.<MovieMold> = new Vector.<MovieMold>();

    public var atlases :Vector.<AtlasMold> = new Vector.<AtlasMold>();

    public static function fromJSON (o :Object) :LibraryMold {
        const mold :LibraryMold = new LibraryMold();
        mold.frameRate = require(o, "frameRate");
        mold.md5 = require(o, "md5");
        for each (var movie :Object in require(o, "movies")) mold.movies.push(MovieMold.fromJSON(movie));
        for each (var atlas :Object in require(o, "atlases")) mold.atlases.push(AtlasMold.fromJSON(atlas));
        return mold;
    }

    public function toJSON (_:*) :Object {
        return {
            frameRate: frameRate,
            md5: md5,
            movies: movies,
            atlases: atlases
        };
    }
}
}
