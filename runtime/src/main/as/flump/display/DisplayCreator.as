//
// Flump - Copyright 2012 Three Rings Design

package flump.display {

import flash.display.BitmapData;
import flash.utils.Dictionary;

import flump.SwfTexture;
import flump.xfl.XflLibrary;
import flump.xfl.XflMovie;
import flump.xfl.XflTexture;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

public class DisplayCreator
{
    public function DisplayCreator (lib :XflLibrary) {
        _lib = lib;
    }

    public function loadMovie (symbol :String) :Movie {
        return new Movie(_lib.get(symbol, XflMovie), loadSymbol);
    }

    public function loadTexture (symbol :String) :DisplayObject {
        if (!_textures.hasOwnProperty(symbol)) {
            const match :Object = FLIPBOOK_TEXTURE.exec(symbol);
            var packed :SwfTexture;
            if (match == null)  {
                packed = SwfTexture.fromTexture(_lib.swf, _lib.get(symbol, XflTexture));
            } else {
                const movieSymbol :String = match[1];
                const frame :int = int(match[2]);
                const movie :XflMovie = _lib.get(movieSymbol, XflMovie);
                if (!movie.flipbook) {
                    throw new Error("Got non-flipbook movie for flipbook texture '" + symbol + "'");
                }
                packed = SwfTexture.fromFlipbook(_lib.swf, movie, frame);
            }
            _textures[symbol] = Texture.fromBitmapData(packed.toBitmapData());
            _textureOffsets[symbol] = packed.offset;
        }
        const image :Image = new Image(_textures[symbol]);
        image.x = _textureOffsets[symbol].x;
        image.y = _textureOffsets[symbol].y;
        const holder :Sprite = new Sprite();
        holder.addChild(image);
        return holder;
    }

    public function loadSymbol (symbol :String) :DisplayObject {
        const match :Object = FLIPBOOK_TEXTURE.exec(symbol);
        if (match != null) return loadTexture(symbol);
        const symbolItem :* = _lib.get(symbol);
        if (symbolItem is XflTexture) return loadTexture(XflTexture(symbolItem).symbol);
        else return loadMovie(XflMovie(symbolItem).symbol);
    }

    protected const _textures :Dictionary = new Dictionary();// symbol to Texture
    protected const _textureOffsets :Dictionary = new Dictionary();// symbol to Point
    protected var _lib :XflLibrary;

    protected static const FLIPBOOK_TEXTURE :RegExp = /^(.*)_flipbook_(\d+)$/;
}
}
