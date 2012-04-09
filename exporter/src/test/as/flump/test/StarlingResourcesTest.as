//
// Flump - Copyright 2012 Three Rings Design

package flump.test {

import flash.filesystem.File;

import flump.display.Movie;
import flump.display.StarlingResources;
import flump.executor.Future;
import flump.executor.VisibleFuture;

import starling.core.Starling;

import com.threerings.util.F;

public class StarlingResourcesTest
{
    public function StarlingResourcesTest (runner :TestRunner, zipFile :File) {
        runner.runAsync("Load Starling Resources", function (finisher :VisibleFuture) :void {
            const loader :Future = StarlingResources.loadURL(zipFile.url);
            loader.succeeded.add(function (res :StarlingResources) :void {
                finisher.succeedAfter(F.callback(checkResources, res));
            });
            loader.failed.add(finisher.fail);
        });
        function checkResources (res :StarlingResources) :void {
            assert(res.movieNames.length == 2, "There should be 2 items in movieNames");
            assert(res.movieNames.indexOf("nesteddance") != -1, "nesteddance should be in movies");
            assert(res.movieNames.indexOf("squaredance") != -1, "squaredance should be in movies");
            const movie :Movie = res.loadMovie("nesteddance");
            assert(res.loadTexture("redsquare") != null);
            assert(movie.name == "nesteddance", "Movies should be named after their mold name");
            assertThrows(F.callback(res.loadTexture, "nesteddance"), "Loaded movie as texture");
            assertThrows(F.callback(res.loadMovie, "redsquare"), "Loaded texture as movie");
            assertThrows(F.callback(res.loadMovie, "no movie with this id "));
            RuntimePlaybackTest.addTests(runner, res);
        }
        checkBadResourcesFail(runner, NO_VERSION, "no version");
        checkBadResourcesFail(runner, WRONG_VERSION, "wrong version");
        checkBadResourcesFail(runner, MALFORMED_JSON, "malformed json");
        checkBadResourcesFail(runner, MISSING_ATLAS, "missing atlas");
    }

    protected function checkBadResourcesFail (runner :TestRunner, badResources :Class, reason :String) :void {
        runner.runAsync("Fail loading resources with " + reason,
            function (future :VisibleFuture) :void {
                const loader :Future = StarlingResources.loadBytes(new badResources());
                loader.succeeded.add(F.callback(future.fail, "Shouldn't load resources with " + reason));
                loader.failed.add(future.succeed);
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
