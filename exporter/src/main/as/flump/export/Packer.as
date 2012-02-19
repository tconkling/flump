//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.geom.Rectangle;

import flump.SwfTexture;
import flump.xfl.XflKeyframe;
import flump.xfl.XflLibrary;
import flump.xfl.XflMovie;
import flump.xfl.XflTexture;

import com.threerings.util.Comparators;

public class Packer
{
    public const atlases :Vector.<Atlas> = new Vector.<Atlas>();

    public function Packer (lib :XflLibrary) {
        _lib = lib;
        for each (var tex :XflTexture in _lib.textures) {
            _unpacked.push(SwfTexture.fromTexture(_lib.swf, tex));
        }
        for each (var movie :XflMovie in _lib.movies) {
            if (!movie.flipbook) continue;
            for each (var kf :XflKeyframe in movie.layers[0].keyframes) {
                _unpacked.push(SwfTexture.fromFlipbook(lib.swf, movie, kf.index));
            }
        }
        _unpacked.sort(Comparators.createReverse(Comparators.createFields(["a", "w", "h"])));
        while (_unpacked.length > 0) pack();
    }

    protected function pack () :void {
        const tex :SwfTexture = _unpacked[0];
        if (tex.w > LARGEST_BIN || tex.h > LARGEST_BIN) throw new Error("Too large to fit in bin");
        for each (var atlas :Atlas in atlases) {
            for each (var bin :Rectangle in atlas.bins) {
                if (tex.w <= bin.width && tex.h <= bin.height) {
                    atlas.place(_unpacked.shift(), bin, false);
                    return;
                } else if (tex.h <= bin.width && tex.w <= bin.height) {
                    atlas.place(_unpacked.shift(), bin, true);
                    return;
                }
            }
        }
        var minBin :int = findOptimalMinBin();
        atlases.push(new Atlas(_lib.location + "/atlas" + atlases.length, minBin, minBin));
        pack();
    }

    protected function findOptimalMinBin () :int {
        var area :int = 0;
        var maxExtent :int = 0;
        for each (var tex :SwfTexture in _unpacked) {
            area += tex.a;
            maxExtent = Math.max(maxExtent, tex.w, tex.h);
        }
        for each (var size :int in BIN_SIZES) {
            if (size >= maxExtent && size * size >= area) return size;
        }
        return LARGEST_BIN;
    }

    protected var _unpacked :Vector.<SwfTexture> = new Vector.<SwfTexture>();

    protected var _lib :XflLibrary;

    private static const BIN_SIZES :Vector.<int> = new <int>[8, 16, 32, 64, 128, 256, 512, 1024];
    private static const LARGEST_BIN :int = BIN_SIZES[BIN_SIZES.length - 1];
}
}
