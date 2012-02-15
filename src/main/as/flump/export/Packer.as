//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Rectangle;

import com.adobe.images.PNGEncoder;

import com.threerings.util.Comparators;

public class Packer
{
    public static const BIN_SIZES :Vector.<int> = new <int>[8, 16, 32, 64, 128, 256, 512, 1024];

    public const atlases :Vector.<Atlas> = new Vector.<Atlas>();

    public function Packer (toPack :Vector.<PackedTexture>) {
        _unpacked = toPack;
        _unpacked.sort(Comparators.createReverse(Comparators.createFields(["a", "w", "h"])));
        var minBin :int = findOptimalMinBin();
        atlases.push(new Atlas(minBin, minBin));
        while (_unpacked.length > 0) pack(_unpacked.shift());
    }

    public function publish (dir :File) :void {
        for (var ii :int = 0; ii < atlases.length; ii++) {
            var atlas :Atlas = atlases[ii];
            var constructed :Sprite = new Sprite();
            for each (var tex :PackedTexture in atlas.textures) {
                constructed.addChild(tex.holder);
                tex.holder.x = tex.atlasX;
                tex.holder.y = tex.atlasY;
            }
            const bd :BitmapData = new BitmapData(atlas.w, atlas.h, true);
            // Clear bitmapdata's default white background with a transparent one
            bd.fillRect(new Rectangle(0, 0, atlas.w, atlas.h), 0);
            bd.draw(constructed);
            var fs :FileStream = new FileStream();
            fs.open(dir.resolvePath(ii + ".png"), FileMode.WRITE);
            fs.writeBytes(PNGEncoder.encode(bd));
            fs.close();
        }
    }

    protected function pack (tex :PackedTexture) :void {
        for each (var atlas :Atlas in atlases) {
            for each (var bin :Rectangle in atlas.bins) {
                if (tex.w <= bin.width && tex.h <= bin.height) {
                    atlas.place(tex, bin, false);
                    return;
                } else if (tex.h <= bin.width && tex.w <= bin.height) {
                    atlas.place(tex, bin, true);
                    return;
                }
            }
        }
        // TODO - allocate another atlas
        throw new Error("Doesn't fit " + tex);
    }

    protected function findOptimalMinBin () :int {
        var area :int = 0;
        var maxExtent :int = 0;
        for each (var tex :PackedTexture in _unpacked) {
            area += tex.a;
            maxExtent = Math.max(maxExtent, tex.w, tex.h);
        }
        for each (var size :int in BIN_SIZES) {
            if (size >= maxExtent && size * size >= area) return size;
        }
        return BIN_SIZES[BIN_SIZES.length -1];
    }

    protected var _unpacked :Vector.<PackedTexture>;
}
}
