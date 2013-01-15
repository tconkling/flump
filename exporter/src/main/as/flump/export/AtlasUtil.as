//
// Flump - Copyright 2013 Flump Authors

package flump.export {
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.utils.IDataOutput;

import com.adobe.images.PNGEncoder;

import starling.core.Starling;
import starling.textures.Texture;

public class AtlasUtil
{
    public static function writePNG (atlas :Atlas, bytes :IDataOutput) :void {
        bytes.writeBytes(PNGEncoder.encode(atlas.toBitmap()));
    }

    public static function toTexture (atlas :Atlas) :Texture {
        var bmd :BitmapData = atlas.toBitmap();
        var tex :Texture = Texture.fromBitmapData(bmd);
        if (!Starling.handleLostContext) {
            bmd.dispose();
        }
        return tex;
    }

    public static function toSprite (atlas :Atlas) :Sprite {
        const bd :Bitmap = new Bitmap(atlas.toBitmap());
        const sprite :Sprite = new Sprite();
        sprite.addChild(bd);
        return sprite;
    }
}
}
