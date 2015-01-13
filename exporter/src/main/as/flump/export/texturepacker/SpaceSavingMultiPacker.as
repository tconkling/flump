package flump.export.texturepacker {

import aspire.util.Log;
import flash.geom.Rectangle;

import flump.SwfTexture;
import flump.export.Atlas;
import flump.export.AtlasImpl;

// packer that tries to use as small total atlas area as possible
public class SpaceSavingMultiPacker extends MultiPackerBase {

    // TODO the last 3 parameters are not needed for this class
    override public function pack(textures :Vector.<SwfTexture>,
                         maxAtlasSize :uint,
                         borderSize :uint,
                         scaleFactor :int,
                         quality :String,
                         filenamePrefix :String) : Vector.<Atlas> {

        var atlases :Vector.<Atlas> = new Vector.<Atlas>();
        while (textures.length > 0) {
            // find the minimum atlas size
            var atlasSize :uint = calculateMinimumSize(textures, borderSize, maxAtlasSize);
            log.info("There are " + textures.length + " unpacked textures, creating new atlas with size " + atlasSize);
            var atlas : AtlasImpl = new AtlasImpl(
                    filenamePrefix + "atlas" + atlases.length,
                    atlasSize, atlasSize,
                    borderSize,
                    scaleFactor,
                    quality);
            atlases.push(atlas);

            // try to put every texture into it
            var packer : MaxRectPackerImpl = new MaxRectPackerImpl(atlasSize, atlasSize);
            for (var i:int = 0; i < textures.length; i++) {
                var swfTexture:SwfTexture = textures[i];
                var w : int = swfTexture.w + (borderSize * 2);
                var h : int = swfTexture.h + (borderSize * 2);
                var rect : Rectangle = packer.quickInsert(w,h);
                if (rect != null) {
                    atlas.place(swfTexture, rect.x, rect.y);
                    textures.splice(i,1);
                    i--;
                }
            }
        }
        return atlases;
    }

    private static const log :Log = Log.getLog(SpaceSavingMultiPacker);
}
}
