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

    public function loadMovie (name :String) :Movie {
        return new Movie(_lib.getLibrary(name, XflMovie), loadLibraryItem);
    }

    public function loadTexture (name :String) :DisplayObject {
        if (!_textures.hasOwnProperty(name)) {
            const match :Object = FLIPBOOK_TEXTURE.exec(name);
            var packed :SwfTexture;
            if (match == null)  {
                packed = SwfTexture.fromTexture(_lib.swf, _lib.getLibrary(name, XflTexture));
            } else {
                const movieName :String = match[1];
                const frame :int = int(match[2]);
                const movie :XflMovie = _lib.getLibrary(movieName, XflMovie);
                if (!movie.flipbook) {
                    throw new Error("Got non-flipbook movie for flipbook texture '" + name + "'");
                }
                packed = SwfTexture.fromFlipbook(_lib.swf, movie, frame);
            }
            _textures[name] = Texture.fromBitmapData(packed.toBitmapData());
            _textureOffsets[name] = packed.offset;
        }
        const image :Image = new Image(_textures[name]);
        image.x = _textureOffsets[name].x;
        image.y = _textureOffsets[name].y;
        const holder :Sprite = new Sprite();
        holder.addChild(image);
        return holder;
    }

    public function loadLibraryItem (name :String) :DisplayObject {
        const match :Object = FLIPBOOK_TEXTURE.exec(name);
        if (match != null) return loadTexture(name);
        const libraryItem :* = _lib.getLibrary(name);
        if (libraryItem is XflTexture) return loadTexture(XflTexture(libraryItem).libraryItem);
        else return loadMovie(XflMovie(libraryItem).libraryItem);
    }

    protected const _textures :Dictionary = new Dictionary();// library name to Texture
    protected const _textureOffsets :Dictionary = new Dictionary();// library name to Point
    protected var _lib :XflLibrary;

    protected static const FLIPBOOK_TEXTURE :RegExp = /^(.*)_flipbook_(\d+)$/;
}
}
