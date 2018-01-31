//
// Flump - Copyright 2013 Flump Authors

package flump.demo {

import flash.utils.ByteArray;

import flump.display.Library;
import flump.display.LibraryLoader;
import flump.display.Movie;
import flump.executor.Future;

import starling.display.Sprite;
import starling.events.Event;

public class DemoScreen extends Sprite
{
    public function DemoScreen () {
        const loader :Future = new LibraryLoader().loadBytes(ByteArray(new MASCOT_ZIP()));
        loader.succeeded.connect(onLibraryLoaded);
        loader.failed.connect(function (e :Error) :void { throw e; });
    }

    protected function onLibraryLoaded (library :Library) :void {
        _movieCreator = new MovieCreator(library);
        var movie :Movie = _movieCreator.createMovie("walk");
        movie.x = 320;
        movie.y = 240;
        addChild(movie);

        // Clean up after ourselves when the screen goes away.
        addEventListener(Event.REMOVED_FROM_STAGE, function (..._) :void {
            _movieCreator.library.dispose();
        });
    }

    protected var _movieCreator :MovieCreator;

    [Embed(source="/mascot.zip", mimeType="application/octet-stream")]
    private static const MASCOT_ZIP :Class;
}
}
