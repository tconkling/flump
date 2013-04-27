//
// Flump - Copyright 2013 Flump Authors

package flump {

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.display.StageQuality;
import flash.geom.Point;
import flash.geom.Rectangle;

import flump.executor.load.LoadedSwf;
import flump.mold.MovieMold;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

public class SwfTexture
{
    public var symbol :String;
    public var origin :Point;
    public var w :int, h :int, a :int;
    public var scale :Number;
    public var quality :String;

    public static function fromFlipbook (lib :XflLibrary, movie :MovieMold, frame :int,
        quality :String = StageQuality.BEST, scale :Number = 1) :SwfTexture {

        const klass :Class = Class(lib.swf.getSymbol(movie.id));
        const clip :MovieClip = MovieClip(new klass());
        clip.gotoAndStop(frame + 1);
        const name :String = movie.id + "_flipbook_" + frame;
        return new SwfTexture(name, clip, scale, quality);
    }

    public static function fromTexture (swf :LoadedSwf, tex :XflTexture,
        quality :String = StageQuality.BEST, scale :Number = 1) :SwfTexture {

        const klass :Class = Class(swf.getSymbol(tex.symbol));
        const instance :Object = new klass();
        const disp :DisplayObject = (instance is BitmapData) ?
            new Bitmap(BitmapData(instance)) : DisplayObject(instance);
        return new SwfTexture(tex.symbol, disp, scale, quality);
    }

    public function SwfTexture (symbol :String, disp :DisplayObject, scale :Number, quality :String) {
        this.symbol = symbol;
        this.scale = scale;
        this.quality = quality;
        _disp = disp;

        origin = getOrigin(_disp, scale);

        const size :Point = getSize(_disp, scale);
        w = size.x;
        h = size.y;
        a = w * h;
    }

    public function toBitmapData (borderPadding :int = 0) :BitmapData {
        const bmd :BitmapData = Util.renderToBitmapData(_disp, w, h, quality, scale);
        return (borderPadding > 0 ? Util.padBitmapBorder(bmd, borderPadding) : bmd);
    }

    public function toString () :String { return "a " + a + " w " + w + " h " + h; }

    protected static function getSize (disp :DisplayObject, scale :Number) :Point {
        const bounds :Rectangle = getBounds(disp, scale);
        return new Point(Math.ceil(bounds.width), Math.ceil(bounds.height));
    }

    protected static function getOrigin (disp :DisplayObject, scale :Number) :Point {
        const bounds :Rectangle = getBounds(disp, scale);
        return new Point(-bounds.x, -bounds.y);
    }

    protected static function getBounds (disp :DisplayObject, scale :Number) :Rectangle {
        const oldScale :Number = disp.scaleX;
        disp.scaleX = disp.scaleY = scale;
        const holder :Sprite = new Sprite();
        holder.addChild(disp);
        const bounds :Rectangle = disp.getBounds(holder);
        disp.scaleX = disp.scaleY = oldScale;
        return bounds;
    }

    protected var _disp :DisplayObject;
}
}
