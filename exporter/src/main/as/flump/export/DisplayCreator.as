//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flash.utils.Dictionary;

import flump.display.Library;
import flump.display.Movie;
import flump.mold.AtlasMold;
import flump.mold.AtlasTextureMold;
import flump.mold.KeyframeMold;
import flump.mold.LayerMold;
import flump.mold.MovieMold;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.textures.Texture;

import com.threerings.util.Map;
import com.threerings.util.maps.ValueComputingMap;

public class DisplayCreator
    implements Library
{
    public function DisplayCreator (lib :XflLibrary) {
        _lib = lib;

        const atlases :Vector.<Atlas> = TexturePacker.withLib(lib).createAtlases();
        for each (var atlas :Atlas in atlases) {
            var mold :AtlasMold = atlas.toMold();
            var baseTexture :Texture = AtlasUtil.toTexture(atlas);
            _baseTextures.push(baseTexture);
            for each (var atlasTexture :AtlasTextureMold in mold.textures) {
                var tex :Texture = Texture.fromTexture(baseTexture, atlasTexture.bounds);
                var creator :ImageCreator =
                    new ImageCreator(tex, atlasTexture.origin, atlasTexture.symbol);
                _imageCreators[atlasTexture.symbol] = creator;
            }
        }
    }

    public function get imageSymbols () :Vector.<String> {
        // Vector.map can't be used to create a Vector of a new type
        const symbols :Vector.<String> = new <String>[];
        for each (var tex :XflTexture in _lib.textures) {
            symbols.push(tex.symbol);
        }
        return symbols;
    }

    public function get movieSymbols () :Vector.<String> {
        // Vector.map can't be used to create a Vector of a new type
        const symbols :Vector.<String> = new <String>[];
        for each (var movie :MovieMold in _lib.movies) {
            symbols.push(movie.id);
        }
        return symbols;
    }

    public function createDisplayObject (id :String) :DisplayObject {
        const imageCreator :ImageCreator = ImageCreator(_imageCreators[id]);
        return (imageCreator != null ? imageCreator.create() : createMovie(id));
    }

    public function createImage (id :String) :Image {
        return Image(createDisplayObject(id));
    }

    public function createMovie (name :String) :Movie {
        return new Movie(_lib.getItem(name, MovieMold), _lib.frameRate, this);
    }

    public function getMemoryUsage (id :String, subtex :Dictionary = null) :int {
        if (id == null) return 0;

        const tex :Texture = getStarlingTexture(id);
        if (tex != null) {
            const usage :int = 4 * tex.width * tex.height;
            if (subtex != null && !subtex.hasOwnProperty(id)) subtex[id] = usage;
            return usage;
        }

        const mold :MovieMold = _lib.getItem(id, MovieMold);
        if (subtex == null) subtex = new Dictionary();
        for each (var layer :LayerMold in mold.layers) {
            for each (var kf :KeyframeMold in layer.keyframes) getMemoryUsage(kf.ref, subtex);
        }
        var subtexUsage :int = 0;
        for (var texName :String in subtex) subtexUsage += subtex[texName];
        return subtexUsage;
    }

    public function dispose () :void {
        if (_baseTextures != null) {
            for each (var tex :Texture in _baseTextures) {
                tex.dispose();
            }
            _baseTextures = null;
            _imageCreators = null;
        }
    }

    /**
     * Gets the maximum number of pixels drawn in a single frame by the given id. If it's
     * a texture, that's just the number of pixels in the texture. For a movie, it's the frame with
     * the largest set of textures present in its keyframe. For movies inside movies, the frame
     * drawn usage is the maximum that movie can draw. We're trying to get the worst case here.
     */
    public function getMaxDrawn (id :String) :int { return _maxDrawn.get(id); }

    protected function loadTexture (symbol :String) :DisplayObject {
        return ImageCreator(_imageCreators[symbol]).create();
    }

    protected function calcMaxDrawn (id :String) :int {
        if (id == null) return 0;

        const tex :Texture = getStarlingTexture(id);
        if (tex != null) return tex.width * tex.height;

        const mold :MovieMold = _lib.getItem(id, MovieMold);
        var maxDrawn :int = 0;
        for (var ii :int = 0; ii < mold.frames; ii++) {
            var drawn :int = 0;
            for each (var layer :LayerMold in mold.layers) {
                var kf :KeyframeMold = layer.keyframeForFrame(ii);
                drawn += kf.visible ? getMaxDrawn(kf.ref) : 0;
            }
            maxDrawn = Math.max(maxDrawn, drawn);
        }
        return maxDrawn;
    }

    private function getStarlingTexture (symbol :String) :Texture {
        if (!_imageCreators.hasOwnProperty(symbol)) {
            return null;
        }
        return ImageCreator(_imageCreators[symbol]).texture;
    }

    protected const _maxDrawn :Map = ValueComputingMap.newMapOf(String, calcMaxDrawn);
    protected var _baseTextures :Vector.<Texture> = new <Texture>[];
    protected var _imageCreators :Dictionary = new Dictionary(); //<name, ImageCreator>
    protected var _lib :XflLibrary;
}
}

import flash.geom.Point;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.textures.Texture;

class ImageCreator {
    public var texture :Texture;
    public var origin :Point;
    public var symbol :String;

    public function ImageCreator (texture :Texture, origin :Point, symbol :String) {
        this.texture = texture;
        this.origin = origin;
        this.symbol = symbol;
    }

    public function create () :DisplayObject {
        const image :Image = new Image(texture);
        image.pivotX = origin.x;
        image.pivotY = origin.y;
        image.name = symbol;
        return image;
    }
}
