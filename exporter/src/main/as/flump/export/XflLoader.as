//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import aspire.util.F;
import aspire.util.Log;

import flash.filesystem.File;
import flash.utils.ByteArray;

import flump.executor.Executor;
import flump.executor.Future;
import flump.executor.FutureTask;
import flump.xfl.ParseError;
import flump.xfl.XflLibrary;

public class XflLoader
{
    public function load (name :String, file :File) :Future {
        log.info("Loading xfl", "path", file.nativePath, "name", name);

        const future :FutureTask = new FutureTask();
        _library = new XflLibrary(name);
        _loader.terminated.connect(function (..._) :void {
            _library.finishLoading();
            future.succeed(_library);
        });

        var loadSWF :Future = _library.loadSWF(file.nativePath + ".swf");
        loadSWF.succeeded.connect(function () :void {
            // Since listLibrary shuts down the executor, wait for the swf to load first
            listLibrary(file);
        });
        loadSWF.failed.connect(F.bind(_loader.shutdown));

        return future;
    }

    protected function listLibrary (file :File) :void {
        const domFile :File = file.resolvePath("DOMDocument.xml");
        const loadDomFile :Future = Files.load(domFile, _loader);
        loadDomFile.succeeded.connect(function (data :ByteArray) :void {
            const symbolPaths :Vector.<String> = _library.parseDocumentFile(
                data, domFile.nativePath);
            for each (var path :String in symbolPaths) {
                parseLibraryFile(file.resolvePath(path));
            }
            _loader.shutdown();
        });
        loadDomFile.failed.connect(function (error :Error) :void {
            _library.addTopLevelError(ParseError.CRIT, error.message, error);
            _loader.shutdown();
        });
    }

    protected function parseLibraryFile (file :File) :void {
        const loadLibraryFile :Future = Files.load(file, _loader);
        loadLibraryFile.succeeded.connect(function (data :ByteArray) :void {
            _library.parseLibraryFile(data, file.nativePath);
        });
        loadLibraryFile.failed.connect(function (error :Error) :void {
            _library.addTopLevelError(ParseError.CRIT, error.message, error);
        });
    }

    protected const _loader :Executor = new Executor();

    protected var _library :XflLibrary;

    private static const log :Log = Log.getLog(XflLoader);
}
}
