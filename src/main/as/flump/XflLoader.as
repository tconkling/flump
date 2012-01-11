//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.filesystem.File;

import executor.Executor;
import executor.Future;
import executor.VisibleFuture;
import executor.load.LoadedSwf;
import executor.load.SwfLoader;

import flump.xfl.XflAnimation;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

import com.threerings.util.F;
import com.threerings.util.Log;

public class XflLoader
{
    public function load (file :File) :Future {
        log.info("Loading xfl", "path", file.nativePath);
        const lister :Executor = new Executor();
        const loader :Executor = new Executor();
        const library :XflLibrary = new XflLibrary();
        Files.list(file.resolvePath("LIBRARY/Animations"), lister).
            succeeded.add(function (files :Array) :void {
                for each (var file :File in files) {
                    Files.load(file,  loader).succeeded.add(function (file :File) :void {
                        library.animations.push(new XflAnimation(bytesToXML(file.data)));
                    });
                }
        });
        Files.list(file.resolvePath("LIBRARY/Textures"), lister).
            succeeded.add(function (files :Array) :void {
                for each (var file: File in files) {
                    Files.load(file, loader).succeeded.add(function (file :File) :void {
                        library.textures.push(new XflTexture(bytesToXML(file.data)));
                    });
                }
        });
        // TODO - construct the swf path for realz
        new SwfLoader().loadFromUrl(new File(file.nativePath + ".swf").url, loader).succeeded.add(
                function (swf :LoadedSwf) :void { library.swf = swf; });
        lister.terminated.add(F.callback(loader.shutdown));
        const future :VisibleFuture = new VisibleFuture();
        loader.terminated.add(function (..._) :void {
            trace("Loaded " + library.animations + " " + library.textures + " " + library.swf);
            future.succeed(library);
        });
        lister.shutdown();
        return future;
    }

    private static const log :Log = Log.getLog(XflLoader);
}
}
