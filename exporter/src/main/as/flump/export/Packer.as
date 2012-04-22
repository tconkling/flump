//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.geom.Point;

import flump.SwfTexture;
import flump.mold.KeyframeMold;
import flump.mold.MovieMold;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

import com.threerings.util.Comparators;

public class Packer
{
    public const atlases :Vector.<Atlas> = new Vector.<Atlas>();

    public function Packer (lib :XflLibrary, scale :Number=1.0, prefix :String="", suffix :String="") {
        for each (var tex :XflTexture in lib.textures) {
            _unpacked.push(SwfTexture.fromTexture(lib.swf, tex, scale));
        }
        for each (var movie :MovieMold in lib.movies) {
            if (!movie.flipbook) continue;
            for each (var kf :KeyframeMold in movie.layers[0].keyframes) {
                _unpacked.push(SwfTexture.fromFlipbook(lib, movie, kf.index, scale));
            }
        }
        _unpacked.sort(Comparators.createReverse(Comparators.createFields(["a", "w", "h"])));
        while (_unpacked.length > 0) {
            // Add a new atlas
            const size :Point = findOptimalSize();
            atlases.push(new Atlas(prefix + "atlas" + atlases.length + suffix, size.x, size.y));

            // Try to pack each texture into any atlas
            for (var ii :int = 0; ii < _unpacked.length; ++ii) {
                var unpacked :SwfTexture = _unpacked[ii];

                if (unpacked.w > MAX_SIZE || unpacked.h > MAX_SIZE) {
                    throw new Error("Too large to fit in an atlas");
                }

                for each (var atlas :Atlas in atlases) {
                    // TODO(bruno): Support rotated textures?
                    if (atlas.place(unpacked)) {
                        _unpacked.splice(ii--, 1);
                        break;
                    }
                }
            }
        }
    }

    // Estimate the optimal size for the next atlas
    protected function findOptimalSize () :Point {
        var area :int = 0;
        var maxW :int = 0;
        var maxH :int = 0;

        for each (var tex :SwfTexture in _unpacked) {
            const w :int = tex.w + Atlas.PADDING;
            const h :int = tex.h + Atlas.PADDING;
            area += w * h;
            maxW = Math.max(maxW, w);
            maxH = Math.max(maxH, h);
        }

        const size :Point = new Point(nextPowerOfTwo(maxW), nextPowerOfTwo(maxH));

        // Double the area until it's big enough
        while (size.x * size.y < area) {
            if (size.x < size.y) size.x *= 2;
            else size.y *= 2;
        }

        size.x = Math.min(size.x, MAX_SIZE);
        size.y = Math.min(size.y, MAX_SIZE);

        return size;
    }

    protected static function nextPowerOfTwo (n :int) :int {
        var p :int = 1;
        while (p < n) p *= 2;
        return p;
    }

    protected const _unpacked :Vector.<SwfTexture> = new Vector.<SwfTexture>();

    // Maximum width or height of a texture atlas
    private static const MAX_SIZE :int = 1024;
}
}
