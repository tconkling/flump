//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.filesystem.File;

import com.adobe.crypto.MD5;
import com.adobe.crypto.MD5Stream;

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
import com.threerings.util.Set;
import com.threerings.util.Sets;
import com.threerings.util.StringUtil;
import com.threerings.util.XmlUtil;

public class XflLoader
{
    public function load (name :String, file :File, overseer :Overseer) :Future {
        log.info("Loading xfl", "path", file.nativePath);
        _overseer = overseer;
        _library.name = name;
        listLibrary(file.resolvePath("LIBRARY"));
        // TODO - construct the swf path for realz
        const loadSwf :Future =
            new SwfLoader().loadFromUrl(new File(file.nativePath + ".swf").url, _loader);
        loadSwf.succeeded.add(function (swf :LoadedSwf) :void { _library.swf = swf; });
        _overseer.monitor(loadSwf, "Load SWF");
        const future :VisibleFuture = new VisibleFuture();
        _lister.terminated.add(F.callback(_loader.shutdown));
        _loader.terminated.add(F.callback(future.succeed, _library));
        return future;
    }

    protected function listLibrary (dirInLibrary :File) :void {
        log.debug("Listing in library", "file", dirInLibrary.nativePath);
        const list :Future = Files.list(dirInLibrary, _lister);
        _listing.add(list);
        list.completed.add(function (..._) :void {
            if (list.isSuccessful) {
                for each (var file :File in list.result) { // It's an array of files
                    if (StringUtil.endsWith(file.nativePath, ".xml")) parseLibraryFile(file);
                    else if (file.isDirectory) listLibrary(file);
                }
            }
            _listing.remove(list);
            if (_listing.isEmpty()) _lister.shutdown();
        });
        _overseer.monitor(list, "List Files");
    }

    protected function parseLibraryFile (file :File) :void {
        var loadLibraryFile :Future = Files.load(file, _loader);
        loadLibraryFile.succeeded.add(_overseer.insulate(function (file :File) :void {
            const xml :XML = bytesToXML(file.data);
            if (xml.name().localName != "DOMSymbolItem") {
                log.debug("Skipping file since its root element isn't DOMSymbolItem",
                    "file", file.nativePath, "rootEl", xml.name().localName)
                return;
            }
            const isSprite :Boolean = XmlUtil.getBooleanAttr(xml, "isSpriteSubclass", false);
            const md5 :String = MD5.hashBytes(file.data);
            log.debug("Parsing for library", "file", file.nativePath, "isSprite", isSprite,
                "md5", md5);
            if (isSprite) {
                _library.textures.push(new XflTexture(xml, md5));
            } else {
                _library.animations.push(new XflAnimation(xml, md5));
            }
        }, "Parse Library File"));
        _overseer.monitor(loadLibraryFile, "Load Library File");

    }

    protected const _listing :Set = Sets.newSetOf(Future);
    protected const _library :XflLibrary = new XflLibrary();
    protected const _lister :Executor = new Executor();
    protected const _loader :Executor = new Executor();
    protected const _hash :MD5Stream = new MD5Stream();

    protected var _overseer :Overseer;

    private static const log :Log = Log.getLog(XflLoader);
}
}
