//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.utils.Dictionary;

import flump.SwfTexture;
import flump.display.Movie;
import flump.mold.KeyframeMold;
import flump.mold.LayerMold;
import flump.mold.MovieMold;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

import com.threerings.util.Map;
import com.threerings.util.maps.ValueComputingMap;

public class DisplayCreator
{
    public function DisplayCreator (lib :XflLibrary) {
        _lib = lib;
    }

    public function loadMovie (name :String) :Movie {
        return new Movie(_lib.get(name, MovieMold), _lib.frameRate, loadId);
    }

    public function getMemoryUsage (id :String, subtex :Dictionary = null) :int {
        if (id == null) return 0;
        if (FLIPBOOK_TEXTURE.exec(id) != null || _lib.get(id) is XflTexture) {
            const tex :Texture = getStarlingTexture(id);
            const usage :int = 4 * tex.width * tex.height;
            if (subtex != null && !subtex.hasOwnProperty(id)) {
                subtex[id] = usage;
            }
            return usage;
        }
        const xflMovie :MovieMold = _lib.get(id, MovieMold);
        if (subtex == null) subtex = new Dictionary();
        for each (var layer :LayerMold in xflMovie.layers) {
            for each (var kf :KeyframeMold in layer.keyframes) getMemoryUsage(kf.ref, subtex);
        }
        var subtexUsage :int = 0;
        for (var texName :String in subtex) subtexUsage += subtex[texName];
        return subtexUsage;
    }

    /**
     * Gets the maximum number of pixels drawn in a single frame by the given id. If it's
     * a texture, that's just the number of pixels in the texture. For a movie, it's the frame with
     * the largest set of textures present in its keyframe. For movies inside movies, the frame
     * drawn usage is the maximum that movie can draw. We're trying to get the worst case here.
     */
    public function getMaxDrawn (id :String) :int { return _maxDrawn.get(id); }

    protected function calcMaxDrawn (id :String) :int {
        if (id == null) return 0;
        if (FLIPBOOK_TEXTURE.exec(id) != null || _lib.get(id) is XflTexture) {
            const tex :Texture = getStarlingTexture(id);
            return tex.width * tex.height;
        }
        const xflMovie :MovieMold = _lib.get(id, MovieMold);
        var maxDrawn :int = 0;
        for (var ii :int = 0; ii < xflMovie.frames; ii++) {
            var drawn :int = 0;
            for each (var layer :LayerMold in xflMovie.layers) {
                var kf :KeyframeMold = layer.keyframeForFrame(ii);
                drawn += kf.visible ? getMaxDrawn(kf.ref) : 0;
            }
            maxDrawn = Math.max(maxDrawn, drawn);
        }
        return maxDrawn;
    }

    private function getStarlingTexture (symbol :String) :Texture {
        if (!_textures.hasOwnProperty(symbol)) {
            const match :Object = FLIPBOOK_TEXTURE.exec(symbol);
            var packed :SwfTexture;
            if (match == null)  {
                packed = SwfTexture.fromTexture(_lib.swf, _lib.get(symbol, XflTexture));
            } else {
                const movieName :String = match[1];
                const frame :int = int(match[2]);
                const movie :MovieMold = _lib.get(movieName, MovieMold);
                if (!movie.flipbook) {
                    throw new Error("Got non-flipbook movie for flipbook texture '" + symbol + "'");
                }
                packed = SwfTexture.fromFlipbook(_lib, movie, frame);
            }
            _textures[symbol] = Texture.fromBitmapData(packed.toBitmapData());
            _textureOffsets[symbol] = packed.offset;
        }
        return _textures[symbol];
    }

    public function loadTexture (symbol :String) :DisplayObject {
        const image :Image = new Image(getStarlingTexture(symbol));
        image.x = _textureOffsets[symbol].x;
        image.y = _textureOffsets[symbol].y;
        const holder :Sprite = new Sprite();
        holder.addChild(image);
        return holder;
    }

    public function loadId (id :String) :DisplayObject {
        const match :Object = FLIPBOOK_TEXTURE.exec(id);
        if (match != null) return loadTexture(id);
        const item :* = _lib.get(id);
        if (item is XflTexture) return loadTexture(XflTexture(item).symbol);
        else return loadMovie(MovieMold(item).id);
    }

    protected var _maxDrawn :Map = ValueComputingMap.newMapOf(String, calcMaxDrawn);
    protected const _textures :Dictionary = new Dictionary();// library name to Texture
    protected const _textureOffsets :Dictionary = new Dictionary();// library name to Point
    protected var _lib :XflLibrary;

    protected static const FLIPBOOK_TEXTURE :RegExp = /^(.*)_flipbook_(\d+)$/;
}
}
