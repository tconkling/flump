//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flash.filesystem.File;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import com.adobe.crypto.MD5;

import flump.Util;
import flump.executor.Executor;
import flump.executor.Future;
import flump.executor.VisibleFuture;
import flump.executor.load.LoadedSwf;
import flump.executor.load.SwfLoader;
import flump.export.Atlas;
import flump.export.Files;
import flump.mold.KeyframeMold;
import flump.mold.LayerMold;
import flump.mold.LibraryMold;
import flump.mold.MovieMold;

import com.threerings.util.Log;
import com.threerings.util.Map;
import com.threerings.util.Maps;
import com.threerings.util.Set;
import com.threerings.util.Sets;
import com.threerings.util.XmlUtil;

public class XflLibrary
{
    use namespace xflns;

    /**
     * When an exported movie contains an unexported movie, it gets assigned a generated symbol
     * name with this prefix.
     */
    public static const IMPLICIT_PREFIX :String = "~";

    public var swf :LoadedSwf;

    public var frameRate :Number;
    public var backgroundColor :int;

    // The MD5 of the published library SWF
    public var md5 :String;

    public var location :String;

    public const movies :Vector.<MovieMold> = new Vector.<MovieMold>();
    public const textures :Vector.<XflTexture> = new Vector.<XflTexture>();

    public function XflLibrary (location :String) {
        this.location = location;
    }

    public function get (id :String, requiredType :Class=null) :* {
        const result :* = _ids[id];
        if (result === undefined) throw new Error("Unknown library item '" + id + "'");
        else if (requiredType != null) return requiredType(result);
        else return result;
    }

    public function isExported (movie :MovieMold) :Boolean {
        return _moldToSymbol.containsKey(movie);
    }

    public function get publishedMovies () :Vector.<MovieMold> {
        const result :Vector.<MovieMold> = new Vector.<MovieMold>();
        for each (var movie :MovieMold in _toPublish.toArray().sortOn("id")) result.push(movie);
        return result;
    }

    public function finishLoading () :void {
        var movie :MovieMold = null;

        // Parse all un-exported movies that are referenced by the exported movies.
        for (var ii :int = 0; ii < movies.length; ++ii) {
            movie = movies[ii];
            for each (var symbolName :String in XflMovie.getSymbolNames(movie).toArray()) {
                var xml :XML = _unexportedMovies.remove(symbolName);
                if (xml != null) parseMovie(xml);
            }
        }

        for each (movie in movies) if (isExported(movie)) addToPublished(movie);
    }

    protected function addToPublished (movie :MovieMold) :void {
        if (!_toPublish.add(movie) || movie.flipbook) return;
        for each (var layer :LayerMold in movie.layers) {
            for each (var kf :KeyframeMold in layer.keyframes) {
                if (kf.ref == null) continue;
                kf.ref = _libraryNameToId.get(kf.ref);
                var item :Object = _ids[kf.ref];
                if (item == null) {
                    addTopLevelError(ParseError.CRIT,
                            "unrecognized library item '" + kf.ref + "'");
                } else if (item is MovieMold) addToPublished(MovieMold(item));
            }
        }
    }

    public function createId (mold :Object, libraryName :String, symbol :String) :String {
        if (symbol != null) _moldToSymbol.put(mold, symbol);
        const id :String = symbol == null ? IMPLICIT_PREFIX + libraryName : symbol;
        _libraryNameToId.put(libraryName, id);
        _ids[id] = mold;
        return id;
    }

    public function getErrors (sev :String=null) :Vector.<ParseError> {
        if (sev == null) return _errors;
        const sevOrdinal :int = ParseError.severityToOrdinal(sev);
        return _errors.filter(function (err :ParseError, ..._) :Boolean {
            return err.sevOrdinal >= sevOrdinal;
        });
    }

    public function get valid () :Boolean { return getErrors(ParseError.CRIT).length == 0; }

    public function addTopLevelError (severity :String, message :String, e :Object=null) :void {
        addError(location, severity, message, e);
    }

    public function addError (location :String, severity :String, message :String, e :Object=null) :void {
        _errors.push(new ParseError(location, severity, message, e));
    }

    public function toJSONString (atlases :Vector.<Atlas>, scale :Number, pretty :Boolean=false) :String {
        return JSON.stringify(toMold(atlases, scale), null, pretty ? "  " : null);
    }

    public function toMold (atlases :Vector.<Atlas>, scale :Number) :LibraryMold {
        const mold :LibraryMold = new LibraryMold();
        mold.frameRate = frameRate;
        mold.md5 = md5;
        mold.movies = publishedMovies.map(function (movie :MovieMold, ..._) :MovieMold {
            return movie.scale(scale);
        });
        for each (var atlas :Atlas in atlases) mold.atlases.push(atlas.toMold());
        return mold;
    }

    public function loadSWF (path :String, loader :Executor=null) :Future {
        const onComplete :VisibleFuture = new VisibleFuture();

        const swfFile :File = new File(path);
        const loadSwfFile :Future = Files.load(swfFile, loader);
        loadSwfFile.succeeded.add(function (data :ByteArray) :void {
            md5 = MD5.hashBytes(data);

            const loadSwf :Future = new SwfLoader().loadFromBytes(data);
            loadSwf.succeeded.add(function (loadedSwf :LoadedSwf) :void {
                swf = loadedSwf;
            });
            loadSwf.failed.add(function (error :Error) :void {
                addTopLevelError(ParseError.CRIT, error.message, error);
            });
            loadSwf.completed.add(onComplete.succeed);
        });
        loadSwfFile.failed.add(function (error :Error) :void {
            addTopLevelError(ParseError.CRIT, error.message, error);
            onComplete.fail(error);
        });

        return onComplete;
    }

    /**
     * @returns A list of paths to symbols in this library.
     */
    public function parseDocumentFile (fileData :ByteArray, path :String) :Vector.<String> {
        const xml :XML = Util.bytesToXML(fileData);
        frameRate = XmlUtil.getNumberAttr(xml, "frameRate", 24);

        const hex :String = XmlUtil.getStringAttr(xml, "backgroundColor", "#ffffff");
        backgroundColor = parseInt(hex.substr(1), 16);

        if (xml.media != null) {
            for each (var bitmap :XML in xml.media.DOMBitmapItem) {
                if (XmlUtil.getBooleanAttr(bitmap, "linkageExportForAS", false)) {
                    textures.push(new XflTexture(this, location, bitmap));
                }
            }
        }

        const paths :Vector.<String> = new Vector.<String>();
        if (xml.symbols != null) {
            for each (var symbolXmlPath :XML in xml.symbols.Include) {
                paths.push("LIBRARY/" + XmlUtil.getStringAttr(symbolXmlPath, "href"));
            }
        }

        return paths;
    }

    public function parseLibraryFile (fileData :ByteArray, path :String) :void {
        const xml :XML = Util.bytesToXML(fileData);
        if (xml.name().localName != "DOMSymbolItem") {
            addTopLevelError(ParseError.DEBUG,
                "Skipping file since its root element isn't DOMSymbolItem");
            return;
        } else if (XmlUtil.getStringAttr(xml, "symbolType", "") == "graphic") {
            addTopLevelError(ParseError.DEBUG, "Skipping file because symbolType=graphic");
            return;
        }

        const isSprite :Boolean = XmlUtil.getBooleanAttr(xml, "isSpriteSubclass", false);
        log.debug("Parsing for library", "file", path, "isSprite", isSprite);
        try {
            if (isSprite) {
                // if "export in first frame" is not set, we won't be able to load the texture
                // from the swf.
                // TODO: remove this restriction by loading the entire swf before reading textures?
                if (!XmlUtil.getBooleanAttr(xml, "linkageExportInFirstFrame", true)) {
                    addError(location + ":" + XmlUtil.getStringAttr(xml, "linkageClassName"),
                        ParseError.CRIT, "\"Export in frame 1\" must be set");
                    return;
                }
                var texture :XflTexture = new XflTexture(this, location, xml);
                if (texture.isValid(swf)) textures.push(texture);
                else addError(location + ":" + texture.symbol, ParseError.CRIT, "Sprite is empty");

            } else {
                // It's a movie. If it's exported, we parse it now.
                // Else, we save it for possible parsing later.
                // (Un-exported movies that are not referenced will not be published.)
                if (XflMovie.isExported(xml)) parseMovie(xml);
                else _unexportedMovies.put(XflMovie.getName(xml), xml);
            }
        } catch (e :Error) {
            var type :String = isSprite ? "sprite" : "movie";
            addTopLevelError(ParseError.CRIT, "Unable to parse " + type + " in " + path, e);
            log.error("Unable to parse " + path, e);
        }
    }

    protected function parseMovie (xml :XML) :void {
        movies.push(XflMovie.parse(this, xml));
    }

    /** Library name to XML for movies in the XFL that are not marked for export */
    protected const _unexportedMovies :Map = Maps.newMapOf(String);

    /** Object to symbol name for all exported textures and movies in the library */
    protected const _moldToSymbol :Map = Maps.newMapOf(Object);

    /** Library name to symbol or generated symbol for all textures and movies in the library */
    protected const _libraryNameToId :Map = Maps.newMapOf(String);

    /** Exported movies or movies used in exported movies. */
    protected const _toPublish :Set = Sets.newSetOf(MovieMold);

    /** Symbol or generated symbol to texture or movie. */
    protected const _ids :Dictionary = new Dictionary();

    protected const _errors :Vector.<ParseError> = new Vector.<ParseError>;

    private static const log :Log = Log.getLog(XflLibrary);
}
}
