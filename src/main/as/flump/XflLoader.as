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

import flump.ParseError;
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
    public function load (name :String, file :File) :Future {
        log.info("Loading xfl", "path", file.nativePath, "name", name);
        _library = new XflLibrary(name);
        listLibrary(file.resolvePath("LIBRARY"));
        // TODO - construct the swf path for realz
        const swfPath :String = new File(file.nativePath + ".swf").url;
        const loadSwf :Future = new SwfLoader().loadFromUrl(swfPath, _loader);
        loadSwf.succeeded.add(function (swf :LoadedSwf) :void { _library.swf = swf; });
        loadSwf.failed.add(function (error :Object) :void {
            _library.addError(ParseErrorSeverity.CRIT, "Unable to load swf " + swfPath, error);
        });
        const future :VisibleFuture = new VisibleFuture();
        _lister.terminated.add(F.callback(_loader.shutdown));
        _loader.terminated.add(function (..._) :void {
            _library.finishLoading();
            future.succeed(_library);
        });
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
            } else {
                _library.addError(ParseErrorSeverity.CRIT,
                    "Unable to list directory " + dirInLibrary.nativePath, list.result);
            }
            _listing.remove(list);
            if (_listing.isEmpty()) _lister.shutdown();
        });
    }

    protected function parseLibraryFile (file :File) :void {
        var loadLibraryFile :Future = Files.load(file, _loader);
        loadLibraryFile.succeeded.add(function (file :File) :void {
            const xml :XML = bytesToXML(file.data);
            if (xml.name().localName != "DOMSymbolItem") {
                _library.addError(ParseErrorSeverity.DEBUG,
                    "Skipping file since its root element isn't DOMSymbolItem");
                return;
            }
            const isSprite :Boolean = XmlUtil.getBooleanAttr(xml, "isSpriteSubclass", false);
            const md5 :String = MD5.hashBytes(file.data);
            log.debug("Parsing for library", "file", file.nativePath, "isSprite", isSprite,
                "md5", md5);
            try {
                if (isSprite) _library.textures.push(new XflTexture(_library.location, xml, md5));
                else _library.animations.push(new XflAnimation(_library.location, xml, md5));
            } catch (e :Error) {
                var type :String = isSprite ? "sprite" : "animation";
                _library.addError(ParseErrorSeverity.CRIT,
                    "Unable to parse " + type + " in " + file.nativePath, e);
            }
        });
        loadLibraryFile.failed.add(function (error :Object) :void {
            _library.addError(ParseErrorSeverity.CRIT,
                "Unable to load file " + file.nativePath, error);
        });
    }

    protected const _listing :Set = Sets.newSetOf(Future);
    protected const _lister :Executor = new Executor();
    protected const _loader :Executor = new Executor();
    protected const _hash :MD5Stream = new MD5Stream();

    protected var _library :XflLibrary;

    private static const log :Log = Log.getLog(XflLoader);
}
}
