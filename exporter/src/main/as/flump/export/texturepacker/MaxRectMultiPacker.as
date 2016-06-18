package flump.export.texturepacker {

import flash.geom.Point;
import flash.geom.Rectangle;

import flump.SwfTexture;
import flump.Util;
import flump.export.Atlas;
import flump.export.AtlasImpl;

// Packer that tries to use as few atlases as possible
public class MaxRectMultiPacker extends MultiPackerBase
{
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

        _atlases = new Vector.<Atlas>();
        while (_unpacked.length > 0) {
            _atlases.push(packIntoAtlas(calculateMinimumSize(_unpacked, _borderSize, _maxAtlasSize)));
        }
        return _atlases;
    }

    private function packIntoAtlas (atlasSize :Point) :Atlas {
        //log.info("Starting to pack into a " + atlasSize.x + "x" + atlasSize.y + " atlas");
        var atlas : AtlasImpl = new AtlasImpl(
                _filenamePrefix + "atlas" + _atlases.length,
                atlasSize.x, atlasSize.y,
                _borderSize, _borderSize,
                _scaleFactor,
                _quality);

        // try to pack it into the given size
        var packer :MaxRectPackerImpl = new MaxRectPackerImpl(atlasSize.x, atlasSize.y);
        var placed :Vector.<SwfTexture> = new Vector.<SwfTexture>();
        var swfTexture :SwfTexture;
        for (var i :int = 0; i < _unpacked.length; i++) {
            swfTexture = _unpacked[i];
            var w :int = swfTexture.w + (_borderSize * 2);
            var h :int = swfTexture.h + (_borderSize * 2);
            var rect :Rectangle = packer.quickInsert(w,h);
            if (rect == null) {
                if (Util.nextPowerOfTwo(atlasSize.x + 1) <= _maxAtlasSize ||
                    Util.nextPowerOfTwo(atlasSize.y + 1) <= _maxAtlasSize) {
                    if (atlasSize.x < atlasSize.y) {
                        atlasSize.x = atlasSize.x * 2;
                    } else {
                        atlasSize.y = atlasSize.y * 2;
                    }
                    //log.debug("Element " + swfTexture.symbol + " does not fit, trying with a " + atlasSize + " texture. Max size is: " + _maxAtlasSize);
                    return packIntoAtlas(atlasSize);
                }
            } else {
                // it fits, put into the atlas
                atlas.place(swfTexture, rect.x, rect.y);
                placed.push(swfTexture);
            }
        }

        // Remove the placed textures from our 'unpacked' list
        for each (swfTexture in placed) {
            _unpacked.splice(_unpacked.indexOf(swfTexture), 1);
        }

        return atlas;
    }

    private var _atlases :Vector.<Atlas>;
    private var _borderSize :uint;
    private var _maxAtlasSize :uint;
    private var _unpacked :Vector.<SwfTexture>;
    private var _scaleFactor :int;
    private var _quality :String;
    private var _filenamePrefix :String;
}
}
