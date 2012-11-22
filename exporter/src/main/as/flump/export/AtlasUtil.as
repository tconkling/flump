//
// Flump - Copyright 2012 Three Rings Design

package flump.export {
import flash.display.Bitmap;
import flash.display.Sprite;
import flash.utils.IDataOutput;

import com.adobe.images.PNGEncoder;

import starling.textures.Texture;

public class AtlasUtil
{
    public static function writePNG (atlas :Atlas, bytes :IDataOutput) :void {
        bytes.writeBytes(PNGEncoder.encode(atlas.toBitmap()));
    }

    public static function toTexture (atlas :Atlas) :Texture {
        return Texture.fromBitmapData(atlas.toBitmap());
    }

    public static function toSprite (atlas :Atlas) :Sprite {
        const bd :Bitmap = new Bitmap(atlas.toBitmap());
        const sprite :Sprite = new Sprite();
        sprite.addChild(bd);
        return sprite;
    }
}
}