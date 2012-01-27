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
    public function load (name :String, file :File, overseer :Overseer) :Future {
        log.info("Loading xfl", "path", file.nativePath);
        const lister :Executor = new Executor();
        const loader :Executor = new Executor();
        const library :XflLibrary = new XflLibrary();
        library.name = name;
        const listAnims :Future = Files.list(file.resolvePath("LIBRARY/Animations"), lister);
        listAnims.succeeded.add(function (files :Array) :void {
            for each (var file :File in files) {
                var loadAnim :Future = Files.load(file, loader);
                loadAnim.succeeded.add(overseer.insulate(function (file :File) :void {
                    library.animations.push(new XflAnimation(bytesToXML(file.data)));
                }, "Parse Animation"));
                overseer.monitor(loadAnim, "Load Animation");
            }
        });
        const listTextures :Future = Files.list(file.resolvePath("LIBRARY/Textures"), lister);
        listTextures.succeeded.add(function (files :Array) :void {
            for each (var file: File in files) {
                var loadTexture :Future = Files.load(file, loader);
                loadTexture.succeeded.add(overseer.insulate(function (file :File) :void {
                    library.textures.push(new XflTexture(bytesToXML(file.data)));
                }, "Parse Texture"));
                overseer.monitor(loadTexture, "Load Texture");
            }
        });
        overseer.monitor(listTextures, "List Files");
        overseer.monitor(listAnims, "List Files");
        // TODO - construct the swf path for realz
        const loadSwf :Future =
            new SwfLoader().loadFromUrl(new File(file.nativePath + ".swf").url, loader);
        loadSwf.succeeded.add(function (swf :LoadedSwf) :void { library.swf = swf; });
        overseer.monitor(loadSwf, "Load SWF");
        lister.terminated.add(F.callback(loader.shutdown));
        const future :VisibleFuture = new VisibleFuture();
        loader.terminated.add(F.callback(future.succeed, library));
        lister.shutdown();
        return future;
    }

    private static const log :Log = Log.getLog(XflLoader);
}
}
