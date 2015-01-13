package flump.export.texturepacker {

import aspire.util.Log;
import flash.geom.Rectangle;

import flump.SwfTexture;
import flump.Util;
import flump.export.Atlas;
import flump.export.AtlasImpl;

// packer that tries to use as small total atlas area as possible
public class SpaceSavingMultiPacker {
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

        var atlases :Vector.<Atlas> = new Vector.<Atlas>();
        while (_unpacked.length > 0) {
            // find the minimum atlas size
            var atlasSize :uint = calculateMinimumSize();
            log.info("There are " + _unpacked.length + " unpacked textures, creating new atlas with size " + atlasSize);
            var atlas : AtlasImpl = new AtlasImpl(
                    filenamePrefix + "atlas" + atlases.length,
                    atlasSize, atlasSize,
                    _borderSize,
                    scaleFactor,
                    quality);
            atlases.push(atlas);

            // try to put every texture into it
            var packer : MaxRectPackerImpl = new MaxRectPackerImpl(atlasSize, atlasSize);
            for (var i:int = 0; i < _unpacked.length; i++) {
                var swfTexture:SwfTexture = _unpacked[i];
                var w : int = swfTexture.w + (_borderSize * 2);
                var h : int = swfTexture.h + (_borderSize * 2);
                var rect : Rectangle = packer.quickInsert(w,h);
                if (rect != null) {
                    atlas.place(swfTexture, rect.x, rect.y);
                    _unpacked.splice(i,1);
                    i--;
                }
            }
        }
        return atlases;
    }

    // Estimate the optimal size for the next atlas
    private function calculateMinimumSize() :uint {
        var minSize : uint = 64;
        for (var i:int = 0; i < _unpacked.length; i++) {
            var texture:SwfTexture = _unpacked[i];
            var w : int = texture.w + (_borderSize * 2);
            var h : int = texture.h + (_borderSize * 2);
            minSize = Math.max(minSize, w, h);
        }
        var minPossibleSize : uint = Util.nextPowerOfTwo(minSize);
        return Math.min(_maxAtlasSize, minPossibleSize);
    }


    private static const log :Log = Log.getLog(SpaceSavingMultiPacker);
    private var _borderSize :uint;
    private var _maxAtlasSize :uint;
    private var _unpacked :Vector.<SwfTexture>;
}
}
