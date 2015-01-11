package flump.export {

import aspire.util.Comparators;
import aspire.util.Log;
import flash.geom.Rectangle;

import flump.SwfTexture;
import flump.Util;
import flump.mold.KeyframeMold;
import flump.mold.MovieMold;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

public class MaxRectPacker
{
    public const atlases :Vector.<Atlas> = new <Atlas>[];
    private static const log :Log = Log.getLog(MaxRectPacker);
    protected const _unpacked :Vector.<SwfTexture> = new <SwfTexture>[];

    private var _textureBorderSize : uint;
    private var _scaleFactor : uint;
    private var _maxAtlasSize : uint;
    private var _filenamePrefix : String;
    private var _quality : String;

    public function MaxRectPacker(libs :Vector.<XflLibrary>, baseScale :Number, scaleFactor :int,
                                  textureBorderSize :int, maxAtlasSize :int,
                                  quality :String, filenamePrefix :String)
    {
        _textureBorderSize = textureBorderSize;
        _filenamePrefix = filenamePrefix;
        _quality = quality;
        _scaleFactor = scaleFactor;
        _maxAtlasSize = maxAtlasSize;

        var scale :Number = baseScale * scaleFactor;

        var useNamespaces :Boolean = libs.length > 1;
        for each (var lib :XflLibrary in libs) {
            for each (var tex :XflTexture in lib.textures) {
                _unpacked.push(SwfTexture.fromTexture(lib, tex, quality, scale, useNamespaces));
            }
            for each (var movie :MovieMold in lib.movies) {
                if (!movie.flipbook) continue;
                for each (var kf :KeyframeMold in movie.layers[0].keyframes) {
                    _unpacked.push(SwfTexture.fromFlipbook(lib, movie, kf.index, quality, scale,
                            useNamespaces));
                }
            }
        }

        _unpacked.sort(Comparators.createReverse(Comparators.createFields(["a", "w", "h"])));

        validateTextureSize(maxAtlasSize);

        var minAtlasSize : uint = calculateMinimumSize(0);
        packIntoAtlas(minAtlasSize, 0);
    }

    private function packIntoAtlas(atlasSize : uint, currentPos : uint) : void {
        log.info("Starting to pack into a",atlasSize,"x",atlasSize,"atlas from item", currentPos);
        var itemsInAtlas : uint = 0;
        var atlas : AtlasImpl = new AtlasImpl(
                _filenamePrefix + "atlas" + atlases.length,
                atlasSize, atlasSize,
                _textureBorderSize,
                _scaleFactor,
                _quality);
        // try to pack it into the given (minimum possible) size
        var packer : MaxRectPackerImpl = new MaxRectPackerImpl(atlasSize, atlasSize);
        for (var i:int = currentPos; i < _unpacked.length; i++) {
            var swfTexture:SwfTexture = _unpacked[i];
            var w : int = swfTexture.w + (_textureBorderSize * 2);
            var h : int = swfTexture.h + (_textureBorderSize * 2);
            var rect : Rectangle = packer.quickInsert(w,h);
            if (rect == null) {
                if (Util.nextPowerOfTwo(atlasSize + 1) < _maxAtlasSize) {
                    // everything does not fit, try with a 2x big one.
                    log.debug("Element", currentPos,  "does not fit, trying with a", Util.nextPowerOfTwo(atlasSize + 1), "texture");
                    packIntoAtlas(Util.nextPowerOfTwo(atlasSize + 1), currentPos);
                    return;
                }
                else {
                    // The texture size cannot grow, make a new atlas
                    atlases.push(atlas);
                    currentPos = currentPos + itemsInAtlas;
                    log.debug("Texture size", atlasSize, "cannot grow because max size is",_maxAtlasSize,". Creating new atlas from pos",currentPos);
                    packIntoAtlas(calculateMinimumSize(currentPos), currentPos);
                    return;
                }
            }
            else {
                // it fits, put into the atlas
                var fits : Boolean = atlas.place(swfTexture);
                if (!fits) {
                    throw new Error("Texture does not fit into the atlas, this is a bug");
                }
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
            var w : int = texture.w + (_textureBorderSize * 2);
            var h : int = texture.h + (_textureBorderSize * 2);
            minSize = Math.max(minSize, w, h);
            area += w * h;
        }
        var minPossibleSize : uint = Util.nextPowerOfTwo( Math.max(minSize, Math.sqrt(area)) );
        return Math.min(_maxAtlasSize, minPossibleSize);
    }

    private function validateTextureSize(maxAtlasSize : uint) : void {
        for each (var unpacked : SwfTexture in _unpacked) {
            var w :int = unpacked.w + (_textureBorderSize * 2);
            var h :int = unpacked.h + (_textureBorderSize * 2);

            if (w > maxAtlasSize || h > maxAtlasSize) {
                throw new Error("Too large to fit in an atlas: '" + unpacked.symbol + "' (" +
                w + "x" + h + ")");
            }
        }
    }
}
}
