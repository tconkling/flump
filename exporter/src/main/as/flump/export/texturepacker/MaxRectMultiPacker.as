package flump.export.texturepacker {
import flump.export.*;

import aspire.util.Log;

import flash.geom.Rectangle;

import flump.SwfTexture;
import flump.Util;

// Packer that tries to use as few atlases as possible
public class MaxRectMultiPacker {

    // TODO the last 3 parameters are not needed for this class
    public function pack(textures :Vector.<SwfTexture>,
                         maxAtlasSize :uint,
                         borderSize :uint,
                         scaleFactor :int,
                         quality :String,
                         filenamePrefix :String) : Vector.<Atlas> {

        _unpacked = textures;
        _borderSize = borderSize;
        _maxAtlasSize = maxAtlasSize;
        _scaleFactor = scaleFactor;
        _quality = quality;
        _filenamePrefix = filenamePrefix;

        atlases = new Vector.<Atlas>();
        var minAtlasSize :uint = calculateMinimumSize(0);
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

    private static const log :Log = Log.getLog(MaxRectMultiPacker);
    private var atlases :Vector.<Atlas>;
    private var _borderSize :uint;
    private var _maxAtlasSize :uint;
    private var _unpacked :Vector.<SwfTexture>;
    private var _scaleFactor :int;
    private var _quality :String;
    private var _filenamePrefix :String;

}
}
