//
// Flump - Copyright 2013 Flump Authors

package flump.export.texturepacker {
import flump.export.*;

import aspire.util.Comparators;

import flash.display.StageQuality;

import flump.SwfTexture;
import flump.mold.KeyframeMold;
import flump.mold.MovieMold;

import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

/**
 * Creates texture atlases from an XflLibrary
 */
public class TexturePacker
{
    public static function withLib (lib :XflLibrary) :TexturePacker {
        return withLibs(new <XflLibrary>[lib]);
    }

    public static function withLibs (libs :Vector.<XflLibrary>) :TexturePacker {
        return new TexturePacker(libs);
    }

    /** @private */
    public function TexturePacker (libs :Vector.<XflLibrary>) {
        _libs = libs;
    }

    public function baseScale (val :Number) :TexturePacker { _baseScale = val; return this; }
    public function scaleFactor (val :int) :TexturePacker {  _scaleFactor = val; return this; }
    public function borderSize (val :int) :TexturePacker { _borderSize = val; return this; }
    public function maxAtlasSize (val :int) :TexturePacker { _maxAtlasSize = val; return this; }
    public function optimizeForSpeed (val :Boolean) :TexturePacker { _optimizeForSpeed = val; return this; }
    public function quality (val :String) :TexturePacker { _quality = val; return this; }
    public function filenamePrefix (val :String) :TexturePacker { _filenamePrefix = val; return this; }

    public function createAtlases () :Vector.<Atlas> {
        const _unpacked :Vector.<SwfTexture> = new <SwfTexture>[];
        var scale :Number = _baseScale * _scaleFactor;
        var useNamespaces :Boolean = _libs.length > 1;
        for each (var lib :XflLibrary in _libs) {
            for each (var tex :XflTexture in lib.textures) {
                _unpacked.push(SwfTexture.fromTexture(lib, tex, _quality, scale, useNamespaces));
            }
            for each (var movie :MovieMold in lib.movies) {
                if (!movie.flipbook) continue;
                for each (var kf :KeyframeMold in movie.layers[0].keyframes) {
                    _unpacked.push(SwfTexture.fromFlipbook(lib, movie, kf.index, _quality, scale,
                            useNamespaces));
                }
            }
        }

        _unpacked.sort(Comparators.createReverse(Comparators.createFields(["a", "w", "h"])));

        for each (var unpacked : SwfTexture in _unpacked) {
            var w :int = unpacked.w + (_borderSize * 2);
            var h :int = unpacked.h + (_borderSize * 2);
            if (w > _maxAtlasSize || h > _maxAtlasSize) {
                throw new Error("Too large to fit in an atlas: '" + unpacked.symbol + "' (" +
                                 w + "x" + h + ")");
            }
        }

        var atlases : Vector.<Atlas>;
        if (_optimizeForSpeed) {
            atlases = new MaxRectMultiPacker().pack(_unpacked, _maxAtlasSize, _borderSize, _scaleFactor, _quality, _filenamePrefix);
        } else {
            atlases = new SpaceSavingMultiPacker().pack(_unpacked, _maxAtlasSize, _borderSize, _scaleFactor, _quality, _filenamePrefix);
        }
        return atlases;
    }

    protected var _libs :Vector.<XflLibrary>;
    protected var _baseScale :Number = 1;
    protected var _scaleFactor :int = 1;
    protected var _borderSize :int = 1;
    protected var _maxAtlasSize :int = 2048;
    protected var _optimizeForSpeed :Boolean = true;
    protected var _filenamePrefix :String = "";
    protected var _quality :String = StageQuality.BEST;
}
}