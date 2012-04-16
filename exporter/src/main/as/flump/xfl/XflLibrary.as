//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flash.utils.Dictionary;

import flump.executor.load.LoadedSwf;
import flump.export.Atlas;
import flump.mold.KeyframeMold;
import flump.mold.LayerMold;
import flump.mold.LibraryMold;
import flump.mold.MovieMold;

import com.threerings.util.Map;
import com.threerings.util.Maps;
import com.threerings.util.Set;
import com.threerings.util.Sets;

public class XflLibrary
{
    /**
     * When an exported movie contains an unexported movie, it gets assigned a generated symbol
     * name with this prefix.
     */
    public static const IMPLICIT_PREFIX :String = "~";

    public var swf :LoadedSwf;

    public var frameRate :Number;

    // The MD5 of the published library SWF
    public var md5 :String;

    public var location :String;

    public const movies :Vector.<MovieMold> = new Vector.<MovieMold>();
    public const textures :Vector.<XflTexture> = new Vector.<XflTexture>();

    public function XflLibrary(location :String) {
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
        for each (var movie :MovieMold in movies) if (isExported(movie)) addToPublished(movie);
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

    public function addTopLevelError(severity :String, message :String, e :Object=null) :void {
        addError(location, severity, message, e);
    }

    public function addError(location :String, severity :String, message :String, e :Object=null) :void {
        _errors.push(new ParseError(location, severity, message, e));
    }

    public function toJSONString (atlases :Vector.<Atlas>, pretty :Boolean=false) :String {
        return JSON.stringify(toMold(atlases), null, pretty ? "  " : null);
    }

    public function toMold (atlases :Vector.<Atlas>) :LibraryMold {
        const mold :LibraryMold = new LibraryMold();
        mold.frameRate = frameRate;
        mold.md5 = md5;
        mold.movies = movies;
        for each (var atlas :Atlas in atlases) mold.atlases.push(atlas.toMold());
        return mold;
    }

    /** Object to symbol name for all exported textures and movies in the library */
    protected const _moldToSymbol :Map = Maps.newMapOf(Object);

    /** Library name to symbol or generated symbol for all textures and movies in the library */
    protected const _libraryNameToId :Map = Maps.newMapOf(String);

    /** Exported movies or movies used in exported movies. */
    protected const _toPublish :Set = Sets.newSetOf(MovieMold);

    /** Symbol or generated symbol to texture or movie. */
    protected const _ids :Dictionary = new Dictionary();

    protected const _errors :Vector.<ParseError> = new Vector.<ParseError>;
}
}
