//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flash.utils.Dictionary;

import flump.executor.load.LoadedSwf;

public class XflLibrary extends XflTopLevelComponent
{
    // When an exported movie contains an unexported movie, it gets assigned a generated symbol name
    // with this prefix.
    public static const IMPLICIT_PREFIX :String = "~";

    public var swf :LoadedSwf;

    // The MD5 of the published library SWF
    public var md5 :String;

    public const movies :Vector.<XflMovie> = new Vector.<XflMovie>();
    public const textures :Vector.<XflTexture> = new Vector.<XflTexture>();

    public function XflLibrary(location :String) {
        super(location);
    }

    public function hasSymbol (symbol :String) :Boolean {
        return _symbols[symbol] !== undefined;
    }

    public function getSymbol (symbol :String, requiredType :Class=null) :* {
        const result :* = _symbols[symbol];
        if (result === undefined) throw new Error("Unknown symbol '" + symbol + "'");
        else if (requiredType != null) return requiredType(result);
        else return result;
    }

    public function getLibrary (name :String, requiredType :Class=null) :* {
        const result :* = _libraryItems[name];
        if (result === undefined) throw new Error("Unknown library item '" + name + "'");
        else if (requiredType != null) return requiredType(result);
        else return result;
    }

    public function finishLoading () :void {
        for each (var tex :XflTexture in textures) {
            _libraryItems[tex.libraryItem] = tex;
            _symbols[tex.symbol] = tex;
        }
        for each (var movie :XflMovie in movies) {
            if (movie.symbol != null) _symbols[movie.symbol] = movie;
            _libraryItems[movie.libraryItem] = movie;
        }

        var generatedId :int = 0;
        for each (movie in movies) {
            for each (var layer :XflLayer in movie.layers) {
                for each (var kf :XflKeyframe in layer.keyframes) {
                    if (kf.libraryItem != null) {
                        var item :Object = _libraryItems[kf.libraryItem];
                        if (item.symbol == null) {
                            // This unexported movie was referenced, generate a symbol name for it
                            item.symbol = IMPLICIT_PREFIX + generatedId;
                            _symbols[item.symbol] = item;
                            ++generatedId;
                        }
                        kf.symbol = item.symbol;
                    }
                }
            }
        }
    }

    override public function getErrors (sev :String=null) :Vector.<ParseError>{
        var base :Vector.<ParseError> = super.getErrors(sev).concat();
        for each (var movie :XflMovie in movies) base = base.concat(movie.getErrors(sev));
        for each (var tex :XflTexture in textures) base = base.concat(tex.getErrors(sev));
        return base;
    }

    protected const _libraryItems :Dictionary = new Dictionary();
    protected const _symbols :Dictionary = new Dictionary();
}
}
