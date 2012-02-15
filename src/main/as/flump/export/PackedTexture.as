//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.geom.Point;
import flash.geom.Rectangle;

import flump.xfl.XflTexture;

public class PackedTexture
{
    public const holder :Sprite = new Sprite();
    public var tex :XflTexture;
    public var offset :Point;
    public var w :int, h :int, a :int;
    public var atlasX :int, atlasY :int;
    public var atlasRotated :Boolean;

    public function PackedTexture (tex :XflTexture, image :DisplayObject) {
        this.tex = tex;
        holder.addChild(image);
        const bounds :Rectangle = image.getBounds(holder);
        image.x = -bounds.x;
        image.y = -bounds.y;
        offset = new Point(bounds.x, bounds.y);
        w = Math.ceil(bounds.width);
        h = Math.ceil(bounds.height);
        a = w * h;
    }

    public function toString () :String {
        return "a " + a + " w " + w + " h " + h + " atlas " + atlasX + ", " + atlasY;
    }
}
}
