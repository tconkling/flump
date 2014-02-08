//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import aspire.util.F;
import aspire.util.Log;

import deng.fzip.FZip;
import deng.fzip.FZipFile;

import flash.filesystem.File;
import flash.utils.ByteArray;

import flump.executor.Executor;
import flump.executor.Future;
import flump.executor.FutureTask;
import flump.xfl.ParseError;
import flump.xfl.XflLibrary;

public class FlaLoader
{
    public function load (name :String, file :File) :Future {
        log.info("Loading fla", "path", file.nativePath, "name", name);

        const future :FutureTask = new FutureTask();
        _library = new XflLibrary(name);
        _loader.terminated.connect(function (..._) :void {
            _library.finishLoading();
            future.succeed(_library);
        });

        var loadSWF :Future = _library.loadSWF(Files.replaceExtension(file, "swf"));
        loadSWF.succeeded.connect(function () :void {
            // Since listLibrary shuts down the executor, wait for the swf to load first
            listLibrary(file);
        });
        loadSWF.failed.connect(F.adapt(_loader.shutdown));

        return future;
    }

    protected function listLibrary (file :File) :void {
        const loadZip :Future = Files.load(file, _loader);
        loadZip.succeeded.connect(function (data :ByteArray) :void {
            const zip :FZip = new FZip();
            zip.loadBytes(data);

            const domFile :FZipFile = zip.getFileByName("DOMDocument.xml");
            const symbolPaths :Vector.<String> = _library.parseDocumentFile(
                domFile.content, domFile.filename);
            for each (var path :String in symbolPaths) {
                var symbolFile :FZipFile = zip.getFileByName(path);
                _library.parseLibraryFile(symbolFile.content, path);
            }
            _loader.shutdown();
        });
        loadZip.failed.connect(function (error :Error) :void {
            _library.addTopLevelError(ParseError.CRIT, error.message, error);
            _loader.shutdown();
        });
    }

    protected const _loader :Executor = new Executor();

    protected var _library :XflLibrary;

    private static const log :Log = Log.getLog(FlaLoader);
}
}
