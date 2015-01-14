package flump.export.texturepacker {

import flump.SwfTexture;
import flump.Util;
import flump.export.Atlas;

public class MultiPackerBase {

    public function pack(textures :Vector.<SwfTexture>,
                         maxAtlasSize :uint,
                         borderSize :uint,
                         scaleFactor :int,
                         quality :String,
                         filenamePrefix :String) : Vector.<Atlas> {
        throw new Error("Abstract function")
    }

    // Estimate the optimal size for the next atlas
    protected function calculateMinimumSize(textures :Vector.<SwfTexture>, borderSize :uint, maxAtlasSize :uint) :uint {
        var minSize : uint = 64;
        var area : uint = 0;
        for (var i:int = 0; i < textures.length; i++) {
            var texture:SwfTexture = textures[i];
            var w : int = texture.w + borderSize * 2;
            var h : int = texture.h + borderSize * 2;
            minSize = Math.max(minSize, w, h);
            area += w * h;
        }
        var minPossibleSize : uint = Util.nextPowerOfTwo( Math.max(minSize, Math.sqrt(area)) );
        return Math.min(maxAtlasSize, minPossibleSize);
    }

}
}
