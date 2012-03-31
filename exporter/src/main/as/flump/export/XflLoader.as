//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;

import com.adobe.crypto.MD5;

import flump.bytesToXML;
import flump.executor.Executor;
import flump.executor.Future;
import flump.executor.VisibleFuture;
import flump.executor.load.LoadedSwf;
import flump.executor.load.SwfLoader;
import flump.xfl.ParseError;
import flump.xfl.XflLibrary;
import flump.xfl.XflMovie;
import flump.xfl.XflTexture;

import com.threerings.util.F;
import com.threerings.util.Log;
import com.threerings.util.XmlUtil;

public class XflLoader
{
    public static const DEFAULT_FLASH_FRAMERATE :Number = 24;

    public function load (name :String, file :File) :Future {
        log.info("Loading xfl", "path", file.nativePath, "name", name);
        _library = new XflLibrary(name);
        listLibrary(file);

        const swfExecutor :Executor = new Executor();
        const future :VisibleFuture = new VisibleFuture();

        const swfFile :File = new File(file.nativePath + ".swf");
        const loadSwfFile :Future = Files.load(swfFile, swfExecutor);
        loadSwfFile.succeeded.add(function (file :File) :void {
            _library.md5 = MD5.hashBytes(file.data);

            const loadSwf :Future = new SwfLoader().loadFromBytes(file.data, swfExecutor);
            loadSwf.succeeded.add(function (swf :LoadedSwf) :void { _library.swf = swf; });
            loadSwf.failed.add(function (error :Object) :void {
                _library.addError(_library, ParseError.CRIT, "Unable to load " + swfFile.nativePath, error);
            });

            swfExecutor.shutdown();
        });
        loadSwfFile.failed.add(function (error :Object) :void {
            _library.addError(_library, ParseError.CRIT, "Unable to read " + swfFile.nativePath, error);
            swfExecutor.shutdown();
        });

        const maybeSucceed :Function = function (..._) :void {
            if (swfExecutor.isTerminated && _loader.isTerminated) {
                _library.finishLoading();
                future.succeed(_library);
            }
        };
        _loader.terminated.add(maybeSucceed);
        swfExecutor.terminated.add(maybeSucceed);

        return future;
    }

    protected function listLibrary (file :File) :void {
        use namespace xflns;
        var loadDomFile :Future = Files.load(file.resolvePath("DOMDocument.xml"), _loader);
        loadDomFile.succeeded.add(function (domFile :File) :void {
            const xml :XML = bytesToXML(domFile.data);

            _library.frameRate = XmlUtil.getNumberAttr(xml, "frameRate", DEFAULT_FLASH_FRAMERATE);

            for each (var symbolXmlPath :XML in xml.symbols.Include) {
                var libraryFile :File =
                    file.resolvePath("LIBRARY/" + XmlUtil.getStringAttr(symbolXmlPath, "href"));
                parseLibraryFile(libraryFile);
            }

            // Done loading
            _loader.shutdown();
        });
    }

    protected function parseLibraryFile (file :File) :void {
        var loadLibraryFile :Future = Files.load(file, _loader);
        loadLibraryFile.succeeded.add(function (file :File) :void {
            const xml :XML = bytesToXML(file.data);
            if (xml.name().localName != "DOMSymbolItem") {
                _library.addError(_library, ParseError.DEBUG,
                    "Skipping file since its root element isn't DOMSymbolItem");
                return;
            } else if (XmlUtil.getStringAttr(xml, "symbolType", "") == "graphic") {
                _library.addError(_library, ParseError.DEBUG,
                    "Skipping file because symbolType=graphic");
                return;
            }

            const isSprite :Boolean = XmlUtil.getBooleanAttr(xml, "isSpriteSubclass", false);
            const md5 :String = MD5.hashBytes(file.data);
            log.debug("Parsing for library", "file", file.nativePath, "isSprite", isSprite,
                "md5", md5);
            try {
                if (isSprite) _library.textures.push(new XflTexture(_library.location, xml, md5));
                else _library.movies.push(XflMovie.parse(_library, xml, md5));
            } catch (e :Error) {
                var type :String = isSprite ? "sprite" : "movie";
                _library.addError(_library, ParseError.CRIT,
                    "Unable to parse " + type + " in " + file.nativePath, e);
            }
        });
        loadLibraryFile.failed.add(function (error :Object) :void {
            _library.addError(_library, ParseError.CRIT,
                "Unable to load file " + file.nativePath, error);
        });
    }

    protected const _loader :Executor = new Executor();

    protected var _library :XflLibrary;

    private static const log :Log = Log.getLog(XflLoader);
}
}
