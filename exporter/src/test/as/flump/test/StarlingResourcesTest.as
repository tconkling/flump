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
    public static function testLoadJSONZip (runner :TestRunner, zipFile :File) :void {
        runner.runAsync("Load JSONZip", function (finisher :FutureTask) :void {
            const loader :Future = new LibraryLoader().loadURL(zipFile.url);
            loader.succeeded.connect(function (res :Library) :void {
                finisher.succeedAfter(F.bind(checkLoadedResources, runner, res, "JSONZip"));
            });
            loader.failed.connect(finisher.fail);
        });
    }

    public static function testLoadJSONDir (runner :TestRunner, dir :File) :void {
        runner.runAsync("Load JSONDir", function (finisher :FutureTask) :void {
            const loader :Future = new LibraryLoader().loadDirectory(dir);
            loader.succeeded.connect(function (res :Library) :void {
                finisher.succeedAfter(F.bind(checkLoadedResources, runner, res, "JSONDir"));
            });
            loader.failed.connect(finisher.fail);
        });
    }

    private static function checkLoadedResources (runner :TestRunner, res :Library, formatName :String) :void {
        var suffix :String = " (" + formatName + ")";
        assert(res.movieSymbols.length == 2, "There should be 2 items in movieNames" + suffix);
        assert(res.movieSymbols.indexOf("nesteddance") != -1, "nesteddance should be in movies" + suffix);
        assert(res.movieSymbols.indexOf("squaredance") != -1, "squaredance should be in movies" + suffix);
        const movie :Movie = res.createMovie("nesteddance");
        assert(res.createImage("redsquare") != null);
        assert(movie.name == "nesteddance", "Movies should be named after their mold name" + suffix);
        assertThrows(F.bind(res.createImage, "nesteddance"), "Loaded movie as texture" + suffix);
        assertThrows(F.bind(res.createMovie, "redsquare"), "Loaded texture as movie" + suffix);
        assertThrows(F.bind(res.createMovie, "no movie with this id"), "Non-existent movie throws" + suffix);
        RuntimePlaybackTest.addTests(runner, res, formatName);
    }

    public static function testBadResources (runner :TestRunner) :void {
        checkBadZipResourcesFail(runner, NO_VERSION, "no version");
        checkBadZipResourcesFail(runner, WRONG_VERSION, "wrong version");
        checkBadZipResourcesFail(runner, MALFORMED_JSON, "malformed json");
        checkBadZipResourcesFail(runner, MISSING_ATLAS, "missing atlas");
        checkBadDirResourcesFail(runner, TestRunner.dist.resolvePath("does_not_exist"),
            "Non-existent directory");
    }

    private static function checkBadDirResourcesFail (runner :TestRunner, dir :File, reason :String) :void {
        runner.runAsync("Dir load fails with " + reason,
            function (future :FutureTask) :void {
                var loader :Future = new LibraryLoader().loadDirectory(dir);
                loader.succeeded.connect(F.bind(future.fail, "Shouldn't load resources with " + reason));
                loader.failed.connect(future.succeed);
            });
    }

    private static function checkBadZipResourcesFail (runner :TestRunner, badResources :Class, reason :String) :void {
        runner.runAsync("Zip load fails with " + reason,
            function (future :FutureTask) :void {
                const loader :Future = new LibraryLoader().loadBytes(new badResources());
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
