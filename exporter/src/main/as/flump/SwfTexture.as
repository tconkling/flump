//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.display.Bitmap;
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

    public static function renderToBitmapData (src :IBitmapDrawable, w :int, h :int, scale :Number = 1,
        multipassScaleThreshold :Number = 0.5) :BitmapData {

        function srcBounds () :Rectangle {
            if (src is BitmapData) {
                return new Rectangle(0, 0, BitmapData(src).width, BitmapData(src).height);
            } else if (src is DisplayObject) {
                return DisplayObject(src).getBounds(DisplayObject(src));
            } else {
                throw new ArgumentError("src must be a a BitmapData or a DisplayObject");
            }
        }

        var bounds :Rectangle = srcBounds();

        if (scale != 1 && !(src is BitmapData)) {
            // for down or up-scaling, render at normal size first, then scale to get the
            // benefit of bitmap smoothing. BitmapData.draw smoothing only works
            // when the source is itself a BitmapData object.
            src = renderToBitmapData(src, Math.ceil(bounds.width), Math.ceil(bounds.height), 1);
            bounds = srcBounds();
        }

        // Don't downscale by more than 50% at a time - this causes Flash's
        // downsampling algorithm to produce really poor results
        var targetScale :Number = scale;
        var targetW :Number = bounds.width;
        var targetH :Number = bounds.height;
        while (targetScale < multipassScaleThreshold) {
            targetW *= multipassScaleThreshold;
            targetH *= multipassScaleThreshold;
            src = renderToBitmapData(src, Math.ceil(targetW), Math.ceil(targetH), multipassScaleThreshold);
            targetScale /= multipassScaleThreshold;
        }
        bounds = srcBounds();

        var bmd :BitmapData = new BitmapData(w, h, true, 0x00);
        var m :Matrix = new Matrix();
        m.translate(-bounds.x, -bounds.y);
        m.scale(targetScale, targetScale);
        bmd.draw(src, m, null, null, null, true);
        return bmd;
    }

    public static function fromFlipbook (lib :XflLibrary, movie :MovieMold, frame :int,
        scale :Number = 1) :SwfTexture {

        const klass :Class = Class(lib.swf.getSymbol(movie.id));
        const clip :MovieClip = MovieClip(new klass());
        clip.gotoAndStop(frame + 1);
        const name :String = movie.id + "_flipbook_" + frame;
        return new SwfTexture(name, clip, scale);
    }

    public static function fromTexture (swf :LoadedSwf, tex :XflTexture,
        scale :Number = 1) :SwfTexture {

        const klass :Class = Class(swf.getSymbol(tex.symbol));
        const instance :Object = new klass();
        const disp :DisplayObject = (instance is BitmapData) ?
            new Bitmap(BitmapData(instance)) : DisplayObject(instance);
        return new SwfTexture(tex.symbol, disp, scale);
    }

    public function SwfTexture (symbol :String, disp :DisplayObject, scale :Number) {
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
        return renderToBitmapData(_disp, w, h, scale);
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
