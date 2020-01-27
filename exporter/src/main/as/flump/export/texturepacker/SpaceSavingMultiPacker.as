package flump.export.texturepacker {

import flash.geom.Point;
import flash.geom.Rectangle;

import flump.SwfTexture;
import flump.Util;
import flump.export.Atlas;
import flump.export.AtlasImpl;

// packer that tries to use as small total atlas area as possible
public class SpaceSavingMultiPacker extends MultiPackerBase
{
    override public function pack(textures :Vector.<SwfTexture>,
                                  maxAtlasSize :uint,
                                  borderSize :uint,
                                  scaleFactor :int,
                                  quality :String,
                                  filenamePrefix :String) : Vector.<Atlas> {

        var atlases :Vector.<Atlas> = new Vector.<Atlas>();

        while (textures.length > 0) {
            // find the optimal atlas size
            var atlasSize :Point = calculateMinimumSize(textures, borderSize, maxAtlasSize);
            if (atlasSize.x < 2048 || atlasSize.y < 2048) {
                // if the filled area is less than FILL_THRESHOLD try to fit them into a smaller texture
                var atlasArea : Number = atlasSize.x * atlasSize.y;
                const FILL_THRESHOLD : Number = 0.75; // TODO this could be moved to a parameter in the UI
                if (calculateArea(textures, borderSize) / atlasArea < FILL_THRESHOLD) {
                    var smallestArea : Point = calculateMinimumDimensions(textures, borderSize);
                    if (smallestArea.x < atlasSize.x && atlasSize.x < atlasSize.y) atlasSize.x = atlasSize.x / 2;
                    else if (smallestArea.y < atlasSize.y && atlasSize.y < atlasSize.x) atlasSize.y = atlasSize.y / 2;
                    else if (smallestArea.x < atlasSize.x) atlasSize.x = atlasSize.x / 2;
                    else if (smallestArea.y < atlasSize.y) atlasSize.y = atlasSize.y / 2;
                }
            }
            //log.info("There are " + textures.length + " unpacked textures, creating new atlas with size " + atlasSize);
            var atlas : AtlasImpl = new AtlasImpl(
                filenamePrefix + "atlas" + atlases.length,
                atlasSize.x, atlasSize.y,
                borderSize, borderSize,
                scaleFactor,
                quality);
            atlases.push(atlas);

            // try to put every texture into it
            var packer :MaxRectPackerImpl = new MaxRectPackerImpl(atlasSize.x, atlasSize.y);
            var prevTex:SwfTexture;
            for (var i:int = 0; i < textures.length; i++) {
                var wasJpg:Boolean = prevTex != null && prevTex.isJpg;

                var swfTexture:SwfTexture = textures[i];
                if (!swfTexture.isJpg && wasJpg)
                {
                    prevTex = null;
                    break;
                }
                var w : int = swfTexture.w + (borderSize * 2);
                var h : int = swfTexture.h + (borderSize * 2);
                var rect : Rectangle = packer.quickInsert(w,h);
                if (rect != null) {
                    if (swfTexture.isJpg && !atlas.isJpg)
                    {
                        trace(atlas.name + " will be JPG");
                        atlas.isJpg = true;
                    }
                    atlas.place(swfTexture, rect.x, rect.y);
                    textures.splice(i,1);
                    i--;
                }

                prevTex = swfTexture;
            }
        }
        return atlases;
    }

    protected function calculateArea (textures :Vector.<SwfTexture>, borderSize :uint) :int {
        var area :int = 0;
        for each (var tex :SwfTexture in textures) {
            const w :int = tex.w + (borderSize * 2);
            const h :int = tex.h + (borderSize * 2);
            area += w * h;
        }
        return area;
    }

    protected function calculateMinimumDimensions (textures :Vector.<SwfTexture>, borderSize :uint) :Point {
        var minSize : Point = new Point(MIN_SIZE, MIN_SIZE);
        for each (var tex :SwfTexture in textures) {
            const w :int = tex.w + (borderSize * 2);
            const h :int = tex.h + (borderSize * 2);
            minSize.x = Math.max(minSize.x, w);
            minSize.y = Math.max(minSize.y, h);
        }
        minSize.x = Util.nextPowerOfTwo(minSize.x);
        minSize.y = Util.nextPowerOfTwo(minSize.y);
        return minSize;
    }
}
}
