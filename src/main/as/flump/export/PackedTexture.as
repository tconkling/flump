//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.filesystem.File;
import flash.geom.Point;
import flash.geom.Rectangle;

import flump.xfl.XflAnimation;
import flump.xfl.XflKeyframe;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

public class PackedTexture
{
    public const holder :Sprite = new Sprite();
    public var name :String;
    public var md5 :String;
    public var offset :Point;
    public var w :int, h :int, a :int;
    public var atlasX :int, atlasY :int;
    public var atlasRotated :Boolean;

    public static function fromFlipbook (anim :XflAnimation, frame :XflKeyframe, lib :XflLibrary)
            :PackedTexture {
        const klass :Class = Class(lib.swf.getSymbol(anim.symbol));
        const movie :MovieClip = MovieClip(new klass());
        movie.gotoAndStop(frame.index + 1);
        return new PackedTexture(anim.md5, anim.name + "_snapshot_" + frame.index, movie);
    }

    public static function fromTexture (tex :XflTexture, lib :XflLibrary) :PackedTexture {
        const klass :Class = Class(lib.swf.getSymbol(tex.symbol));
        const image :Sprite = Sprite(new klass());
        return new PackedTexture(tex.md5, tex.name, image);
    }

    public function PackedTexture(md5 :String, name :String, disp :DisplayObject) {
        this.md5 = md5;
        this.name = name;
        holder.addChild(disp);
        const bounds :Rectangle = disp.getBounds(holder);
        disp.x = -bounds.x;
        disp.y = -bounds.y;
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
