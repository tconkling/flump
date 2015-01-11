//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import aspire.util.Comparators;
import aspire.util.Log;

import flash.display.StageQuality;
import flash.geom.Rectangle;

import flump.SwfTexture;
import flump.Util;
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
    public function quality (val :String) :TexturePacker { _quality = val; return this; }
    public function filenamePrefix (val :String) :TexturePacker { _filenamePrefix = val; return this; }

    public function createAtlases () :Vector.<Atlas> {
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

        validateTextureSize(_maxAtlasSize);

        var minAtlasSize : uint = calculateMinimumSize(0);
        packIntoAtlas(minAtlasSize, 0);

        return atlases;
    }

    private function packIntoAtlas(atlasSize : uint, currentPos : uint) : void {
        log.info("Starting to pack into a " + atlasSize + "x" + atlasSize + " atlas from item " + currentPos);
        var itemsInAtlas : uint = 0;
        var atlas : AtlasImpl = new AtlasImpl(
                _filenamePrefix + "atlas" + atlases.length,
                atlasSize, atlasSize,
                _borderSize,
                _scaleFactor,
                _quality);
        // try to pack it into the given (minimum possible) size
        var packer : MaxRectPackerImpl = new MaxRectPackerImpl(atlasSize, atlasSize);
        for (var i:int = currentPos; i < _unpacked.length; i++) {
            var swfTexture:SwfTexture = _unpacked[i];
            var w : int = swfTexture.w + (_borderSize * 2);
            var h : int = swfTexture.h + (_borderSize * 2);
            var rect : Rectangle = packer.quickInsert(w,h);
            if (rect == null) {
                if (Util.nextPowerOfTwo(atlasSize + 1) < _maxAtlasSize) {
                    // everything does not fit, try with a 2x big one.
                    log.debug("Element " + currentPos + " does not fit, trying with a " + Util.nextPowerOfTwo(atlasSize + 1) + " texture");
                    packIntoAtlas(Util.nextPowerOfTwo(atlasSize + 1), currentPos);
                    return;
                }
                else {
                    // The texture size cannot grow, make a new atlas
                    atlases.push(atlas);
                    currentPos = currentPos + itemsInAtlas;
                    log.debug("Texture size " + atlasSize + " cannot grow because max size is " + _maxAtlasSize + ". Creating new atlas from pos" + currentPos);
                    packIntoAtlas(calculateMinimumSize(currentPos), currentPos);
                    return;
                }
            }
            else {
                // it fits, put into the atlas
                atlas.place(swfTexture, rect.x, rect.y);

                itemsInAtlas++;
                if (i == _unpacked.length - 1) {
                    atlases.push(atlas);
                    log.debug("Packed everything, num atlases:",atlases.length);
                }
            }
        }
    }

    // Calculates the minimum possible size to speed up calculation.
    private function calculateMinimumSize(offset : uint) :uint {
        var minSize : uint = 2;
        var area : uint = 0;
        for (var i:int = offset; i < _unpacked.length; i++) {
            var texture:SwfTexture = _unpacked[i];
            var w : int = texture.w + (_borderSize * 2);
            var h : int = texture.h + (_borderSize * 2);
            minSize = Math.max(minSize, w, h);
            area += w * h;
        }
        var minPossibleSize : uint = Util.nextPowerOfTwo( Math.max(minSize, Math.sqrt(area)) );
        return Math.min(_maxAtlasSize, minPossibleSize);
    }

    private function validateTextureSize(maxAtlasSize : uint) : void {
        for each (var unpacked : SwfTexture in _unpacked) {
            var w :int = unpacked.w + (_borderSize * 2);
            var h :int = unpacked.h + (_borderSize * 2);

            if (w > maxAtlasSize || h > maxAtlasSize) {
                throw new Error("Too large to fit in an atlas: '" + unpacked.symbol + "' (" +
                w + "x" + h + ")");
            }
        }
    }

    protected var _libs :Vector.<XflLibrary>;
    protected var _baseScale :Number = 1;
    protected var _scaleFactor :int = 1;
    protected var _borderSize :int = 1;
    protected var _maxAtlasSize :int = 2048;
    protected var _filenamePrefix :String = "";
    protected var _quality :String = StageQuality.BEST;

    private const atlases :Vector.<Atlas> = new <Atlas>[];
    private static const log :Log = Log.getLog(TexturePacker);
    protected const _unpacked :Vector.<SwfTexture> = new <SwfTexture>[];
}
}