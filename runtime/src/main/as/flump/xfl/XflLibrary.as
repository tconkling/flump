//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flash.utils.Dictionary;

import flump.executor.load.LoadedSwf;

public class XflLibrary extends XflTopLevelComponent
{
    public var swf :LoadedSwf;
    public const movies :Vector.<XflMovie> = new Vector.<XflMovie>();
    public const textures :Vector.<XflTexture> = new Vector.<XflTexture>();

    public function XflLibrary(location :String) {
        super(location);
    }

    public function get (symbol :String, requiredType :Class=null) :* {
        const result :* = _symbols[symbol];
        if (result === undefined) throw new Error("Unknown symbol '" + symbol + "'");
        else if (requiredType != null) return requiredType(result);
        else return result;
    }

    public function finishLoading () :void {
        const libraryItemToSymbol :Dictionary = new Dictionary();
        for each (var tex :XflTexture in textures) {
            _symbols[tex.symbol] = tex;
            libraryItemToSymbol[tex.libraryItem] = tex.symbol;
        }
        for each (var movie :XflMovie in movies) {
            _symbols[movie.libraryItem] = movie;
            for each (var layer :XflLayer in movie.layers) {
                for each (var kf :XflKeyframe in layer.keyframes) {
                    if (kf.libraryItem != null) kf.symbol = libraryItemToSymbol[kf.libraryItem];
                }
            }
        }
        for each (movie in movies) movie.checkSymbols(_symbols);
    }

    override public function getErrors (sev :String=null) :Vector.<ParseError>{
        var base :Vector.<ParseError> = super.getErrors(sev).concat();
        for each (var movie :XflMovie in movies) base = base.concat(movie.getErrors(sev));
        for each (var tex :XflTexture in textures) base = base.concat(tex.getErrors(sev));
        return base;
    }

    protected const _symbols :Dictionary = new Dictionary();
}
}
