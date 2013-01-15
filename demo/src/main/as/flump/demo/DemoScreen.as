//
// Flump - Copyright 2013 Flump Authors

package flump.demo {

import flash.utils.ByteArray;

import starling.display.Sprite;

import flump.display.Library;
import flump.display.LibraryLoader;
import flump.display.Movie;
import flump.executor.Future;

public class DemoScreen extends Sprite
{
    public function DemoScreen () {
        const loader :Future = LibraryLoader.loadBytes(ByteArray(new MASCOT_ZIP()));
        loader.succeeded.add(onLibraryLoaded);
        loader.failed.add(function (e :Error) :void { throw e; });
    }

    protected function onLibraryLoaded (library :Library) :void {
        _movieCreator = new MovieCreator(library);
        var movie :Movie = _movieCreator.createMovie("walk");
        movie.x = 320;
        movie.y = 240;
        addChild(movie);
    }

    protected var _movieCreator :MovieCreator;

    [Embed(source="/mascot.zip", mimeType="application/octet-stream")]
    private static const MASCOT_ZIP :Class;
}
}
