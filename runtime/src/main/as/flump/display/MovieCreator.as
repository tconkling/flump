package flump.display {

import flump.mold.MovieMold;

import starling.display.DisplayObject;

public class MovieCreator
    implements SymbolCreator
{
    public var mold :MovieMold;
    public var frameRate :Number;

    public function MovieCreator (mold :MovieMold, frameRate :Number) {
        this.mold = mold;
        this.frameRate = frameRate;
    }

    public function create (library :Library, cloneOf: DisplayObject = null) :DisplayObject {
        var co:Movie;
        if (cloneOf != null)
        {
            if (!(cloneOf is Movie))
            {
                throw new Error("Movie should be cloned from Movie!");
            }
            co = cloneOf as Movie;
        }

        return new Movie(mold, frameRate, library, co);
    }
}
}
