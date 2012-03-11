//
// Flump - Copyright 2012 Three Rings Design

package flump.display {

import flash.display.BitmapData;
import flash.utils.Dictionary;

import flump.SwfTexture;
import flump.xfl.XflKeyframe;
import flump.xfl.XflLayer;
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
        return new Movie(_lib.getLibrary(name, XflMovie), loadId);
    }

    public function getMemoryUsage (name :String, subtex :Dictionary = null) :int {
        if (name == null) return 0;
        if (FLIPBOOK_TEXTURE.exec(name) != null || _lib.getLibrary(name) is XflTexture) {
            const tex :Texture = getStarlingTexture(name);
            const usage :int = tex.width * tex.height;
            if (subtex != null && !subtex.hasOwnProperty(name)) {
                subtex[name] = usage;
            }
            return usage;
        }
        const xflMovie :XflMovie = _lib.getLibrary(name, XflMovie);
        if (subtex == null) subtex = new Dictionary();
        for each (var layer :XflLayer in xflMovie.layers) {
            for each (var kf :XflKeyframe in layer.keyframes) {
                getMemoryUsage(kf.id, subtex);
            }
        }
        var subtexUsage :int = 0;
        for (var texName :String in subtex) subtexUsage += subtex[texName];
        return subtexUsage;
    }

    private function getStarlingTexture (name :String) :Texture {
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
        return _textures[name];
    }

    public function loadTexture (name :String) :DisplayObject {
        const image :Image = new Image(getStarlingTexture(name));
        image.x = _textureOffsets[name].x;
        image.y = _textureOffsets[name].y;
        const holder :Sprite = new Sprite();
        holder.addChild(image);
        return holder;
    }

    public function loadId (id :String) :DisplayObject {
        const match :Object = FLIPBOOK_TEXTURE.exec(id);
        if (match != null) return loadTexture(id);
        const libraryItem :* = _lib.getLibrary(id);
        if (libraryItem is XflTexture) return loadTexture(XflTexture(libraryItem).libraryItem);
        else return loadMovie(XflMovie(libraryItem).libraryItem);
    }

    protected const _textures :Dictionary = new Dictionary();// library name to Texture
    protected const _textureOffsets :Dictionary = new Dictionary();// library name to Point
    protected var _lib :XflLibrary;

    protected static const FLIPBOOK_TEXTURE :RegExp = /^(.*)_flipbook_(\d+)$/;
}
}
