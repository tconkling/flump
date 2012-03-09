//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.geom.Point;
import flash.geom.Rectangle;

import flump.executor.load.LoadedSwf;
import flump.xfl.XflMovie;
import flump.xfl.XflTexture;

public class SwfTexture
{
    public const holder :Sprite = new Sprite();
    public var symbol :String;
    public var libraryItem :String;
    public var md5 :String;
    public var offset :Point;
    public var w :int, h :int, a :int;
    public var scale :Number;

    public static function renderToBitmapData (target :DisplayObject, width :int,
        height :int) :BitmapData {

        const bd :BitmapData = new BitmapData(width, height, true);
        // Clear bitmapdata's default white background with a transparent one
        bd.fillRect(new Rectangle(0, 0, width, height), 0);
        bd.draw(target);
        return bd;
    }

    public static function fromFlipbook (swf :LoadedSwf, movie :XflMovie, frame :int,
        scale :Number = 1) :SwfTexture {

        const klass :Class = Class(swf.getSymbol(movie.symbol));
        const clip :MovieClip = MovieClip(new klass());
        clip.gotoAndStop(frame + 1);
        var name :String = movie.libraryItem + "_flipbook_" + frame;
        return new SwfTexture(movie.md5, name, name, clip, scale);
    }

    public static function fromTexture (swf :LoadedSwf, tex :XflTexture,
        scale :Number = 1) :SwfTexture {

        const klass :Class = Class(swf.getSymbol(tex.symbol));
        const image :Sprite = Sprite(new klass());
        return new SwfTexture(tex.md5, tex.symbol, tex.libraryItem, image, scale);
    }

    public function SwfTexture(md5 :String, symbol :String, libraryItem :String,
        disp :DisplayObject, scale :Number) {

        this.md5 = md5;
        this.symbol = symbol;
        this.libraryItem = libraryItem;
        this.scale = scale;
        disp.scaleX = disp.scaleY = scale;
        holder.addChild(disp);
        const bounds :Rectangle = disp.getBounds(holder);
        disp.x = -bounds.x;
        disp.y = -bounds.y;
        offset = new Point(bounds.x, bounds.y);
        w = Math.ceil(bounds.width);
        h = Math.ceil(bounds.height);
        a = w * h;
    }

    public function toBitmapData () :BitmapData { return renderToBitmapData(holder, w, h); }

    public function toString () :String {
        return "a " + a + " w " + w + " h " + h;
    }
}
}
