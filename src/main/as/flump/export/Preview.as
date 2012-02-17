//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.display.BitmapData;
import flash.utils.Dictionary;

import flump.display.Movie;
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
        return new Movie(_lib.lookup(symbol, XflMovie), loadSymbol);
    }

    public function loadTexture (symbol :String) :DisplayObject {
        const xflTex :XflTexture = _lib.lookup(symbol, XflTexture);
        if (!_textures.hasOwnProperty(symbol)) {
            const packed :PackedTexture = PackedTexture.fromTexture(xflTex, _lib);
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
        const symbolItem :* = _lib.lookup(symbol);
        if (symbolItem is XflTexture) return loadTexture(XflTexture(symbolItem).symbol);
        else return loadMovie(XflMovie(symbolItem).symbol);
    }

    protected const _textures :Dictionary = new Dictionary();// symbol to Texture
    protected const _textureOffsets :Dictionary = new Dictionary();// symbol to Point
    protected var _lib :XflLibrary;
}
}
