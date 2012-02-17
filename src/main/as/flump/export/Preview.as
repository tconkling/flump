//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.display.BitmapData;
import flash.utils.Dictionary;

import flump.display.Movie;
import flump.xfl.XflKeyframe;
import flump.xfl.XflLibrary;
import flump.xfl.XflMovie;
import flump.xfl.XflTexture;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

import com.threerings.util.Preconditions;

public class Preview extends Sprite
{
    public function init (lib :XflLibrary) :void {
        Preconditions.checkState(_lib == null, "Preview has already been initted");
        _lib = lib;
    }

    public function loadMovie (symbol :String) :Movie {
        return new Movie(_lib.get(symbol, XflMovie), loadSymbol);
    }

    public function loadTexture (symbol :String) :DisplayObject {
        if (!_textures.hasOwnProperty(symbol)) {
            const match :Object = FLIPBOOK_TEXTURE.exec(symbol);
            var packed :PackedTexture;
            if (match == null)  {
                packed = PackedTexture.fromTexture(_lib.get(symbol, XflTexture), _lib);
            } else {
                const movieSymbol :String = match[1];
                const frame :int = int(match[2]);
                const movie :XflMovie = _lib.get(movieSymbol, XflMovie);
                Preconditions.checkState(movie.flipbook,
                    "Got non-flipbook movie for flipbook texture '" + symbol + "'?");
                const kf :XflKeyframe = movie.layers[0].keyframeForFrame(frame)
                packed = PackedTexture.fromFlipbook(movie, kf, _lib);
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
