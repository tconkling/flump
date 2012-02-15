//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.geom.Rectangle;

import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

import com.threerings.util.Comparators;

public class Packer
{
    public static const BIN_SIZES :Vector.<int> = new <int>[8, 16, 32, 64, 128, 256, 512, 1024];

    public const atlases :Vector.<Atlas> = new Vector.<Atlas>();

    public function Packer (lib :XflLibrary) {
        for each (var tex :XflTexture in lib.textures) {
            _unpacked.push(new PackedTexture(tex, lib));
        }
        _unpacked.sort(Comparators.createReverse(Comparators.createFields(["a", "w", "h"])));
        var minBin :int = findOptimalMinBin();
        atlases.push(new Atlas(lib.location + "/atlas0", minBin, minBin));
        while (_unpacked.length > 0) pack(_unpacked.shift());
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

    protected var _unpacked :Vector.<PackedTexture> = new Vector.<PackedTexture>();
}
}
