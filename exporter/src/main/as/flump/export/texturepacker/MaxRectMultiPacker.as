package flump.export.texturepacker {

import aspire.util.Log;

import flash.geom.Rectangle;

import flump.SwfTexture;
import flump.Util;
import flump.export.Atlas;
import flump.export.AtlasImpl;

// Packer that tries to use as few atlases as possible
public class MaxRectMultiPacker extends MultiPackerBase {

    // TODO the last 3 parameters are not needed for this class
    override public function pack(textures :Vector.<SwfTexture>,
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
        packIntoAtlas(calculateMinimumSize(_unpacked, _borderSize, _maxAtlasSize));
        return atlases;
    }

    private function packIntoAtlas(atlasSize : uint) : void {
        log.info("Starting to pack into a " + atlasSize + "x" + atlasSize + " atlas");
        var atlas : AtlasImpl = new AtlasImpl(
                _filenamePrefix + "atlas" + atlases.length,
                atlasSize, atlasSize,
                _borderSize,
                _scaleFactor,
                _quality);
        // try to pack it into the given size
        var packer : MaxRectPackerImpl = new MaxRectPackerImpl(atlasSize, atlasSize);
        var placed : Vector.<SwfTexture> = new Vector.<SwfTexture>();
        for (var i:int = 0; i < _unpacked.length; i++) {
            var swfTexture:SwfTexture = _unpacked[i];
            var w : int = swfTexture.w + (_borderSize * 2);
            var h : int = swfTexture.h + (_borderSize * 2);
            var rect : Rectangle = packer.quickInsert(w,h);
            if (rect == null) {
                if (Util.nextPowerOfTwo(atlasSize + 1) < _maxAtlasSize) {
                    // everything does not fit, try with a 2x big one.
                    log.debug("Element " + i + " does not fit, trying with a " + Util.nextPowerOfTwo(atlasSize + 1) + " texture");
                    packIntoAtlas(Util.nextPowerOfTwo(atlasSize + 1));
                    return;
                }
            }
            else {
                // it fits, put into the atlas
                atlas.place(swfTexture, rect.x, rect.y);
                placed.push(swfTexture);
            }
        }
        while (placed.length > 0) {
            _unpacked.splice(_unpacked.indexOf(placed.pop()),1);
        }
        atlases.push(atlas);
        if (_unpacked.length > 0) {
            packIntoAtlas(calculateMinimumSize(_unpacked, _borderSize, _maxAtlasSize));
        }
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
