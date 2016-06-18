//
// Flump - Copyright 2013 Flump Authors

package flump.export.texturepacker {

import aspire.util.Comparators;

import flash.display.StageQuality;

import flump.SwfTexture;
import flump.Util;
import flump.export.Atlas;
import flump.export.AtlasImpl;
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
        const unpackedTextures :Vector.<SwfTexture> = new <SwfTexture>[];
        var scale :Number = _baseScale * _scaleFactor;
        var useNamespaces :Boolean = _libs.length > 1;
        for each (var lib :XflLibrary in _libs) {
            for each (var tex :XflTexture in lib.textures) {
                unpackedTextures.push(SwfTexture.fromTexture(lib, tex, _quality, scale, useNamespaces));
            }
            for each (var movie :MovieMold in lib.movies) {
                if (!movie.flipbook) continue;
                for each (var kf :KeyframeMold in movie.layers[0].keyframes) {
                    unpackedTextures.push(SwfTexture.fromFlipbook(lib, movie, kf.index, _quality, scale,
                            useNamespaces));
                }
            }
        }

        var w :int;
        var h :int;

        // Special-case if we have just a single texture.
        // If the texture will fit exactly in an atlas, width- or height-wise, we don't pad it
        if (unpackedTextures.length == 1) {
            var singleTex :SwfTexture = unpackedTextures[0];
            w = Util.nextPowerOfTwo(singleTex.w);
            h = Util.nextPowerOfTwo(singleTex.h);
            if (w <= _maxAtlasSize && h <= _maxAtlasSize) {
                var xPad :int = (w == singleTex.w ? 0 : _borderSize);
                var yPad :int = (h == singleTex.h ? 0 : _borderSize);

                var singleAtlas :AtlasImpl = new AtlasImpl(
                    _filenamePrefix + "atlas0",
                    w, h,
                    xPad, yPad,
                    _scaleFactor,
                    _quality);
                singleAtlas.place(singleTex, 0, 0);
                return new <Atlas>[singleAtlas];
            }
        }

        for each (var unpacked : SwfTexture in unpackedTextures) {
            w = unpacked.w + (_borderSize * 2);
            h = unpacked.h + (_borderSize * 2);
            if (w > _maxAtlasSize || h > _maxAtlasSize) {
                throw new Error("Too large to fit in an atlas: '" + unpacked.symbol + "' (" +
                                 w + "x" + h + ")");
            }
        }

        unpackedTextures.sort(Comparators.createReverse(Comparators.createFields(["a", "w", "h"])));

        var packer :MultiPackerBase = (_optimizeForSpeed ?
            new MaxRectMultiPacker() :
            new SpaceSavingMultiPacker());

        return packer.pack(unpackedTextures, _maxAtlasSize, _borderSize, _scaleFactor, _quality, _filenamePrefix);
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
