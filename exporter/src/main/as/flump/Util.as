//
// Flump - Copyright 2013 Flump Authors

package flump {

import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.IBitmapDrawable;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.ByteArray;

import starling.display.Quad;
import starling.display.Sprite;

public class Util
{
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
        originIcon.flatten();
        return originIcon;
    }

    /**
     * Extends src's border pixels by the given amount.
     * (We do this to textures in an atlas in order to prevent artifacts that come from
     * the GPU sampling just beyond a texture's bounds.)
     */
    public static function padBitmapBorder (src :IBitmapDrawable, paddingSize :int) :BitmapData {
        var srcBounds :Rectangle = getBitmapDrawableBounds(src);
        var w :int = Math.ceil(srcBounds.width);
        var h :int = Math.ceil(srcBounds.height);

        var bmd :BitmapData = new BitmapData(w + (paddingSize * 2), h + (paddingSize * 2), true, 0x00);

        // draw the original bitmap
        var m :Matrix = new Matrix();
        m.translate(-srcBounds.x + paddingSize, -srcBounds.y + paddingSize);
        bmd.draw(src, m, null, null, null, /*smoothing=*/false);

        var srcRect :Rectangle = new Rectangle();
        var dst :Point = new Point();
        var yy :int;
        var xx :int;

        // copy top row
        srcRect.x = paddingSize;
        srcRect.y = paddingSize;
        srcRect.width = w;
        srcRect.height = 1;
        dst.x = paddingSize;
        for (yy = 0; yy < paddingSize; ++yy) {
            dst.y = yy;
            bmd.copyPixels(bmd, srcRect, dst);
        }

        // copy bottom row
        srcRect.x = paddingSize;
        srcRect.y = h + paddingSize - 1;
        srcRect.width = w;
        srcRect.height = 1;
        dst.x = paddingSize;
        for (yy = 0; yy < paddingSize; ++yy) {
            dst.y = h + paddingSize + yy;
            bmd.copyPixels(bmd, srcRect, dst);
        }

        // copy left column
        srcRect.x = paddingSize;
        srcRect.y = paddingSize;
        srcRect.width = 1;
        srcRect.height = h;
        dst.y = paddingSize;
        for (xx = 0; xx < paddingSize; ++xx) {
            dst.x = xx;
            bmd.copyPixels(bmd, srcRect, dst);
        }

        // copy right column
        srcRect.x = w + paddingSize - 1;
        srcRect.y = paddingSize;
        srcRect.width = 1;
        srcRect.height = h;
        dst.y = paddingSize;
        for (xx = 0; xx < paddingSize; ++xx) {
            dst.x = w + paddingSize + xx;
            bmd.copyPixels(bmd, srcRect, dst);
        }

        return bmd;
    }

    public static function renderToBitmapData (src :IBitmapDrawable, w :int, h :int,
        scale :Number = 1, multipassScaleThreshold :Number = 0.5) :BitmapData {

        var bounds :Rectangle = getBitmapDrawableBounds(src);

        if (scale != 1 && !(src is BitmapData)) {
            // for down or up-scaling, render at normal size first, then scale to get the
            // benefit of bitmap smoothing. BitmapData.draw smoothing only works
            // when the source is itself a BitmapData object.
            src = renderToBitmapData(src, Math.ceil(bounds.width), Math.ceil(bounds.height), 1);
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
            src = renderToBitmapData(src, Math.ceil(targetW), Math.ceil(targetH), multipassScaleThreshold);
            targetScale /= multipassScaleThreshold;
        }
        bounds = getBitmapDrawableBounds(src);

        var bmd :BitmapData = new BitmapData(w, h, true, 0x00);
        var m :Matrix = new Matrix();
        m.translate(-bounds.x, -bounds.y);
        m.scale(targetScale, targetScale);
        bmd.draw(src, m, null, null, null, true);
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
}
}
