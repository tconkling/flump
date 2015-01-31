package flump.export.texturepacker {

import flash.geom.Point;

import flump.SwfTexture;
import flump.Util;
import flump.Util;
import flump.export.Atlas;

public class MultiPackerBase {

    public static const MIN_SIZE : uint = 128;

    public function pack(textures :Vector.<SwfTexture>,
                         maxAtlasSize :uint,
                         borderSize :uint,
                         scaleFactor :int,
                         quality :String,
                         filenamePrefix :String) : Vector.<Atlas> {
        throw new Error("Abstract function")
    }

    // Estimate the optimal size for the next atlas
    protected function calculateMinimumSize(textures :Vector.<SwfTexture>, borderSize :uint, maxAtlasSize :uint) :Point {
        var area :int = 0;
        var maxW :int = MIN_SIZE;
        var maxH :int = MIN_SIZE;

        for each (var tex :SwfTexture in textures) {
            const w :int = tex.w + (borderSize * 2);
            const h :int = tex.h + (borderSize * 2);
            area += w * h;
            maxW = Math.max(maxW, w);
            maxH = Math.max(maxH, h);
        }

        const size :Point = new Point(Util.nextPowerOfTwo(maxW), Util.nextPowerOfTwo(maxH));

        // Double the area until it's big enough
        while (size.x * size.y < area) {
            if (size.x < size.y) size.x *= 2;
            else size.y *= 2;
        }

        size.x = Math.min(size.x, maxAtlasSize);
        size.y = Math.min(size.y, maxAtlasSize);

        return size;
    }

}
}
