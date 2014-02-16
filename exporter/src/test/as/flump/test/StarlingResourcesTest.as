//
// Flump - Copyright 2013 Flump Authors

package flump.test {

import aspire.util.F;

import flash.filesystem.File;

import flump.display.Library;
import flump.display.LibraryLoader;
import flump.display.Movie;
import flump.executor.Future;
import flump.executor.FutureTask;

public class StarlingResourcesTest
{
    public function StarlingResourcesTest (runner :TestRunner, zipFile :File) {
        runner.runAsync("Load Starling Resources", function (finisher :FutureTask) :void {
            const loader :Future = LibraryLoader.loadURL(zipFile.url);
            loader.succeeded.connect(function (res :Library) :void {
                finisher.succeedAfter(F.bind(checkResources, res));
            });
            loader.failed.connect(finisher.fail);
        });
        function checkResources (res :Library) :void {
            assert(res.movieSymbols.length == 2, "There should be 2 items in movieNames");
            assert(res.movieSymbols.indexOf("nesteddance") != -1, "nesteddance should be in movies");
            assert(res.movieSymbols.indexOf("squaredance") != -1, "squaredance should be in movies");
            const movie :Movie = res.createMovie("nesteddance");
            assert(res.createImage("redsquare") != null);
            assert(movie.name == "nesteddance", "Movies should be named after their mold name");
            assertThrows(F.bind(res.createImage, "nesteddance"), "Loaded movie as texture");
            assertThrows(F.bind(res.createMovie, "redsquare"), "Loaded texture as movie");
            assertThrows(F.bind(res.createMovie, "no movie with this id "));
            RuntimePlaybackTest.addTests(runner, res);
        }
        checkBadResourcesFail(runner, NO_VERSION, "no version");
        checkBadResourcesFail(runner, WRONG_VERSION, "wrong version");
        checkBadResourcesFail(runner, MALFORMED_JSON, "malformed json");
        checkBadResourcesFail(runner, MISSING_ATLAS, "missing atlas");
    }

    protected function checkBadResourcesFail (runner :TestRunner, badResources :Class, reason :String) :void {
        runner.runAsync("Fail loading resources with " + reason,
            function (future :FutureTask) :void {
                const loader :Future = LibraryLoader.loadBytes(new badResources());
                loader.succeeded.connect(F.bind(future.fail, "Shouldn't load resources with " + reason));
                loader.failed.connect(future.succeed);
        });
    }

    [Embed(source="wrong_version.zip", mimeType="application/octet-stream")]
    private static const WRONG_VERSION :Class;

    [Embed(source="malformed_json.zip", mimeType="application/octet-stream")]
    private static const MALFORMED_JSON :Class;

    [Embed(source="no_version.zip", mimeType="application/octet-stream")]
    private static const NO_VERSION :Class;

    [Embed(source="missing_atlas.zip", mimeType="application/octet-stream")]
    private static const MISSING_ATLAS :Class;
}
}
