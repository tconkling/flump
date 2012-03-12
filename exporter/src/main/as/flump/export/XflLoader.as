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
import flump.xfl.XmlConverter;

import com.threerings.util.F;
import com.threerings.util.Log;
import com.threerings.util.XmlUtil;

public class XflLoader
{
    public function load (name :String, file :File) :Future {
        log.info("Loading xfl", "path", file.nativePath, "name", name);
        _library = new XflLibrary(name);
        listLibrary(file);

        // TODO - construct the swf path for realz
        const swfFile :Future = Files.load(new File(file.nativePath + ".swf"), _loader);
        swfFile.succeeded.add(function (file :File) :void {
            _library.md5 = MD5.hashBytes(file.data);

            const loadSwf :Future = new SwfLoader().loadFromBytes(file.data, _loader);
            loadSwf.succeeded.add(function (swf :LoadedSwf) :void { _library.swf = swf; });
            loadSwf.failed.add(function (error :Object) :void {
                _library.addError(ParseError.CRIT, "Unable to load swf " + file.nativePath, error);
            });
        });

        const future :VisibleFuture = new VisibleFuture();
        _loader.terminated.add(function (..._) :void {
            _library.finishLoading();
            future.succeed(_library);
        });
        return future;
    }

    protected function listLibrary (file :File) :void {
        use namespace xflns;
        var loadDomFile :Future = Files.load(file.resolvePath("DOMDocument.xml"), _loader);
        loadDomFile.succeeded.add(function (domFile :File) :void {
            const xml :XML = bytesToXML(domFile.data);
            for each (var symbolXmlPath :XML in xml.symbols.Include) {
                const conv :XmlConverter = new XmlConverter(symbolXmlPath);
                var libraryFile :File = file.resolvePath("LIBRARY/" + conv.getStringAttr("href"));
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
                _library.addError(ParseError.DEBUG,
                    "Skipping file since its root element isn't DOMSymbolItem");
                return;
            }
            const isSprite :Boolean = XmlUtil.getBooleanAttr(xml, "isSpriteSubclass", false);
            const md5 :String = MD5.hashBytes(file.data);
            log.debug("Parsing for library", "file", file.nativePath, "isSprite", isSprite,
                "md5", md5);
            try {
                if (isSprite) _library.textures.push(new XflTexture(_library.location, xml, md5));
                else _library.movies.push(new XflMovie(_library.location, xml, md5));
            } catch (e :Error) {
                var type :String = isSprite ? "sprite" : "movie";
                _library.addError(ParseError.CRIT,
                    "Unable to parse " + type + " in " + file.nativePath, e);
            }
        });
        loadLibraryFile.failed.add(function (error :Object) :void {
            _library.addError(ParseError.CRIT,
                "Unable to load file " + file.nativePath, error);
        });
    }

    protected const _loader :Executor = new Executor();

    protected var _library :XflLibrary;

    private static const log :Log = Log.getLog(XflLoader);
}
}
