//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.display.Sprite;
import flash.filesystem.File;
import flash.geom.Point;
import flash.geom.Rectangle;

import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

public class PackedTexture
{
    public const holder :Sprite = new Sprite();
    public var tex :XflTexture;
    public var offset :Point;
    public var w :int, h :int, a :int;
    public var atlasX :int, atlasY :int;
    public var atlasRotated :Boolean;

    public function PackedTexture (tex :XflTexture, lib :XflLibrary) {
        this.tex = tex;

        const klass :Class = Class(lib.swf.getSymbol(tex.symbol));
        const image :Sprite = Sprite(new klass());
        holder.addChild(image);
        const bounds :Rectangle = image.getBounds(holder);
        image.x = -bounds.x;
        image.y = -bounds.y;
        offset = new Point(bounds.x, bounds.y);
        w = Math.ceil(bounds.width);
        h = Math.ceil(bounds.height);
        a = w * h;
    }

    public function publish (dest :File) :void { PngPublisher.publish(dest, w, h, holder); }

    public function toString () :String {
        return "a " + a + " w " + w + " h " + h + " atlas " + atlasX + ", " + atlasY;
    }
}
}
