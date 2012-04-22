//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.IBitmapDrawable;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import flump.executor.load.LoadedSwf;
import flump.mold.MovieMold;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

public class SwfTexture
{
    public var symbol :String;
    public var offset :Point;
    public var w :int, h :int, a :int;
    public var scale :Number;

    // The MD5 of the symbol XML in the library, or null if there is no associated symbol
    public var md5 :String;

    public static function renderToBitmapData (target :IBitmapDrawable, width :int,
        height :int, scale :Number = 1) :BitmapData {

        const bd :BitmapData = new BitmapData(width, height, true, 0x00);
        const m :Matrix = new Matrix();
        m.scale(scale, scale);
        bd.draw(target, m, null, null, null, true);
        return bd;
    }

    public static function fromFlipbook (lib :XflLibrary, movie :MovieMold, frame :int,
        scale :Number = 1) :SwfTexture {

        const klass :Class = Class(lib.swf.getSymbol(movie.id));
        const clip :MovieClip = MovieClip(new klass());
        clip.gotoAndStop(frame + 1);
        const name :String = movie.id + "_flipbook_" + frame;
        return new SwfTexture(null, name, clip, scale);
    }

    public static function fromTexture (swf :LoadedSwf, tex :XflTexture,
        scale :Number = 1) :SwfTexture {

        const klass :Class = Class(swf.getSymbol(tex.symbol));
        const image :Sprite = Sprite(new klass());
        return new SwfTexture(tex.md5, tex.symbol, image, scale);
    }

    public function SwfTexture (md5 :String, symbol :String, disp :DisplayObject, scale :Number) {

        this.md5 = md5;
        this.symbol = symbol;
        this.scale = scale;
        _disp = disp;

        offset = getOffset(_disp, scale);

        const size :Point = getSize(_disp, scale);
        w = size.x;
        h = size.y;
        a = w * h;
    }

    public function toBitmapData () :BitmapData {
        const holder :Sprite = new Sprite();

        if (scale < 1) {
            // for downlscaling, render at normal size first, then scale to get the
            // benefit of bitmap smoothing. BitmapData.draw smoothing only works
            // when the source is itself a BitmapData object.
            const fullsizeOffset :Point = getOffset(_disp, 1);
            const fullSize :Point = getSize(_disp, 1);
            _disp.x = -fullsizeOffset.x;
            _disp.y = -fullsizeOffset.y;
            holder.addChild(_disp);
            const bmd :BitmapData = renderToBitmapData(holder, fullSize.x, fullSize.y, 1);
            return renderToBitmapData(bmd, w, h, scale);

        } else {
            _disp.x = getOffset(_disp, scale).x;
            _disp.y = getOffset(_disp, scale).y;
            holder.addChild(_disp);
            return renderToBitmapData(holder, w, h, scale);
        }
    }

    public function toString () :String { return "a " + a + " w " + w + " h " + h; }

    protected static function getSize (disp :DisplayObject, scale :Number) :Point {
        const bounds :Rectangle = getBounds(disp, scale);
        return new Point(Math.ceil(bounds.width), Math.ceil(bounds.height));
    }

    protected static function getOffset (disp :DisplayObject, scale :Number) :Point {
        const bounds :Rectangle = getBounds(disp, scale);
        return new Point(bounds.x, bounds.y);
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
