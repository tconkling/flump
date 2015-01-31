package flump.export.texturepacker {

import aspire.util.Log;

import flash.geom.Point;

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

    private function packIntoAtlas(atlasSize : Point) : void {
        //log.info("Starting to pack into a " + atlasSize.x + "x" + atlasSize.y + " atlas");
        var atlas : AtlasImpl = new AtlasImpl(
                _filenamePrefix + "atlas" + atlases.length,
                atlasSize.x, atlasSize.y,
                _borderSize,
                _scaleFactor,
                _quality);
        // try to pack it into the given size
        var packer : MaxRectPackerImpl = new MaxRectPackerImpl(atlasSize.x, atlasSize.y);
        var placed : Vector.<SwfTexture> = new Vector.<SwfTexture>();
        for (var i:int = 0; i < _unpacked.length; i++) {
            var swfTexture:SwfTexture = _unpacked[i];
            var w : int = swfTexture.w + (_borderSize * 2);
            var h : int = swfTexture.h + (_borderSize * 2);
            var rect : Rectangle = packer.quickInsert(w,h);
            if (rect == null) {
                if (Util.nextPowerOfTwo(atlasSize.x + 1) <= _maxAtlasSize ||
                    Util.nextPowerOfTwo(atlasSize.y + 1) <= _maxAtlasSize) {
                    if (atlasSize.x < atlasSize.y) atlasSize.x = atlasSize.x * 2;
                    else atlasSize.y = atlasSize.y * 2;
                    //log.debug("Element " + swfTexture.symbol + " does not fit, trying with a " + atlasSize + " texture. Max size is: " + _maxAtlasSize);
                    packIntoAtlas(atlasSize);
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
