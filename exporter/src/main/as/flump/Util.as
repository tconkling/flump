//
// Flump - Copyright 2013 Flump Authors

package flump {

import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.IBitmapDrawable;
import flash.events.Event;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.ByteArray;

import starling.display.Quad;
import starling.display.Sprite;

public class Util
{
    /**
    * Initialize the target object with values present in the initProps object and the defaults
    * object. Neither initProps nor defaults will be modified.
    * @throws ReferenceError if a property cannot be set on the target object.
    *
    * @param target any object or class instance.
    * @param initProps a plain Object hash containing names and properties to set on the target
    *                  object.
    * @param defaults a plain Object hash containing names and properties to set on the target
    *                 object, only if the same property name does not exist in initProps.
    * @param maskProps a plain Object hash containing names of properties to omit setting
    *                  from the initProps object. This allows you to add custom properties to
    *                  initProps without having to modify the value from your callers.
    */
    public static function init (
        target :Object, initProps :Object, defaults :Object = null, maskProps :Object = null) :void
    {
        var prop :String;
        for (prop in initProps) {
            if (maskProps == null || !(prop in maskProps)) {
                target[prop] = initProps[prop];
            }
        }

        if (defaults != null) {
            for (prop in defaults) {
                if (initProps == null || !(prop in initProps)) {
                    target[prop] = defaults[prop];
                }
            }
        }
    }

    /**
     * Creates a listener that removes itself from the event source and calls f with args.
     *
     * Functionally equivalent to justOnce(callback(f, args));
     */
    public static function callbackOnce (f: Function, ... args) :Function
    {
        return function listener (event :Event) :void {
            event.currentTarget.removeEventListener(event.type, listener);
            f.apply(this, args);
        }
    }

    /**
     * Returns a property of an object by name if the object contains the property, otherwise
     * returns a default value.
     */
    public static function getDefault (props :Object, name :String, defaultValue :Object) :Object
    {
        return (name in props) ? props[name] : defaultValue;
    }

    public static function bytesToXML (bytes :ByteArray) :XML {
        return new XML(bytes.readUTFBytes(bytes.length));
    }

    /** Creates the little black and white origin crosshairs icon */
    public static function createOriginIcon () :Sprite {
        var originIcon :Sprite = new Sprite();
        originIcon.addChild(fillRect(3, 7, 0xffffff));
        originIcon.addChild(fillRect(7, 3, 0xffffff));
        originIcon.addChild(fillRect(1, 9, 0x000000));
        originIcon.addChild(fillRect(9, 1, 0x000000));
        return originIcon;
    }

    /**
     * Extends src's border pixels by the given amount.
     * (We do this to textures in an atlas in order to prevent artifacts that come from
     * the GPU sampling just beyond a texture's bounds.)
     */
    public static function padBitmapBorder (src :IBitmapDrawable, xPad :int, yPad :int) :BitmapData {
        var srcBounds :Rectangle = getBitmapDrawableBounds(src);
        var w :int = Math.ceil(srcBounds.width);
        var h :int = Math.ceil(srcBounds.height);

        var bmd :BitmapData = new BitmapData(w + (xPad * 2), h + (yPad * 2), true, 0x00);

        // draw the original bitmap
        var m :Matrix = new Matrix();
        m.translate(-srcBounds.x + xPad, -srcBounds.y + yPad);
        bmd.draw(src, m, null, null, null, /*smoothing=*/false);

        var srcRect :Rectangle = new Rectangle();
        var dst :Point = new Point();
        var yy :int;
        var xx :int;

        // copy top row
        srcRect.x = xPad;
        srcRect.y = yPad;
        srcRect.width = w;
        srcRect.height = 1;
        dst.x = xPad;
        for (yy = 0; yy < yPad; ++yy) {
            dst.y = yy;
            bmd.copyPixels(bmd, srcRect, dst);
        }

        // copy bottom row
        srcRect.x = xPad;
        srcRect.y = h + yPad - 1;
        srcRect.width = w;
        srcRect.height = 1;
        dst.x = xPad;
        for (yy = 0; yy < yPad; ++yy) {
            dst.y = h + yPad + yy;
            bmd.copyPixels(bmd, srcRect, dst);
        }

        // copy left column
        srcRect.x = xPad;
        srcRect.y = yPad;
        srcRect.width = 1;
        srcRect.height = h;
        dst.y = yPad;
        for (xx = 0; xx < xPad; ++xx) {
            dst.x = xx;
            bmd.copyPixels(bmd, srcRect, dst);
        }

        // copy right column
        srcRect.x = w + xPad - 1;
        srcRect.y = yPad;
        srcRect.width = 1;
        srcRect.height = h;
        dst.y = yPad;
        for (xx = 0; xx < xPad; ++xx) {
            dst.x = w + xPad + xx;
            bmd.copyPixels(bmd, srcRect, dst);
        }

        return bmd;
    }

    public static function renderToBitmapData (src :IBitmapDrawable, w :int, h :int,
        quality:String, scale :Number = 1, multipassScaleThreshold :Number = 0.5) :BitmapData {

        var bounds :Rectangle = getBitmapDrawableBounds(src);

        if (scale != 1 && !(src is BitmapData)) {
            // for down or up-scaling, render at normal size first, then scale to get the
            // benefit of bitmap smoothing. BitmapData.draw smoothing only works
            // when the source is itself a BitmapData object.
            src = renderToBitmapData(src, Math.ceil(bounds.width), Math.ceil(bounds.height), quality, 1);
            bounds = getBitmapDrawableBounds(src);
        }

        // Don't downscale by more than 50% at a time - this causes Flash's
        // downsampling algorithm to produce really poor results
        var targetScale :Number = scale;
        var targetW :Number = bounds.width;
        var targetH :Number = bounds.height;
        while (targetScale < multipassScaleThreshold) {
            targetW *= multipassScaleThreshold;
            targetH *= multipassScaleThreshold;
            src = renderToBitmapData(src, Math.ceil(targetW), Math.ceil(targetH), quality, multipassScaleThreshold);
            targetScale /= multipassScaleThreshold;
        }
        bounds = getBitmapDrawableBounds(src);

        var bmd :BitmapData = new BitmapData(w, h, true, 0x00);
        var m :Matrix = new Matrix();
        m.translate(-bounds.x, -bounds.y);
        m.scale(targetScale, targetScale);
        bmd.drawWithQuality(src, m, null, null, null, true, quality);
        return bmd;
    }

    protected static function getBitmapDrawableBounds (src :IBitmapDrawable) :Rectangle {
        if (src is BitmapData) {
            return new Rectangle(0, 0, BitmapData(src).width, BitmapData(src).height);
        } else if (src is DisplayObject) {
            return DisplayObject(src).getBounds(DisplayObject(src));
        } else {
            throw new ArgumentError("src must be a a BitmapData or a DisplayObject");
        }
    }

    protected static function fillRect (width :Number, height :Number, color :uint) :Quad {
        var quad :Quad = new Quad(width, height, color);
        quad.pivotX = width / 2;
        quad.pivotY = height / 2;
        return quad;
    }

    /** Returns the smallest number >= n that is a power of two. */
    public static function nextPowerOfTwo (n :int) :int {
        var p :int = 1;
        while (p < n) p *= 2;
        return p;
    }
}
}
