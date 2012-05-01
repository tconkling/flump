//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;
import flash.utils.ByteArray;

import flump.executor.Executor;
import flump.executor.Future;
import flump.executor.VisibleFuture;
import flump.xfl.ParseError;
import flump.xfl.XflLibrary;

import com.threerings.util.F;
import com.threerings.util.Log;

public class XflLoader
{
    public function load (name :String, file :File) :Future {
        log.info("Loading xfl", "path", file.nativePath, "name", name);

        const future :VisibleFuture = new VisibleFuture();
        _library = new XflLibrary(name);
        _loader.terminated.add(function (..._) :void {
            _library.finishLoading();
            future.succeed(_library);
        });

        var loadSWF :Future = _library.loadSWF(file.nativePath + ".swf");
        loadSWF.succeeded.add(function () :void {
            // Since listLibrary shuts down the executor, wait for the swf to load first
            listLibrary(file);
        });
        loadSWF.failed.add(_loader.shutdown);

        return future;
    }

    protected function listLibrary (file :File) :void {
        const domFile :File = file.resolvePath("DOMDocument.xml");
        const loadDomFile :Future = Files.load(domFile, _loader);
        loadDomFile.succeeded.add(function (data :ByteArray) :void {
            const symbolPaths :Vector.<String> = _library.parseDocumentFile(
                data, domFile.nativePath);
            for each (var path :String in symbolPaths) {
                parseLibraryFile(file.resolvePath(path));
            }
            _loader.shutdown();
        });
        loadDomFile.failed.add(function (error :Object) :void {
            _library.addTopLevelError(ParseError.CRIT, "Unable to read " + domFile.nativePath,
                error);
            _loader.shutdown();
        });
    }

    protected function parseLibraryFile (file :File) :void {
        const loadLibraryFile :Future = Files.load(file, _loader);
        loadLibraryFile.succeeded.add(function (data :ByteArray) :void {
            _library.parseLibraryFile(data, file.nativePath);
        });
        loadLibraryFile.failed.add(function (error :Object) :void {
            _library.addTopLevelError(ParseError.CRIT, "Unable to read " + file.nativePath, error);
        });
    }

    protected const _loader :Executor = new Executor();

    protected var _library :XflLibrary;

    private static const log :Log = Log.getLog(XflLoader);
}
}
