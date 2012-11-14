//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.IBitmapDrawable;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.utils.ByteArray;

public class Util
{
    public static function bytesToXML (bytes :ByteArray) :XML {
        return new XML(bytes.readUTFBytes(bytes.length));
    }

    public static function renderToBitmapData (src :IBitmapDrawable, w :int, h :int,
        scale :Number = 1, multipassScaleThreshold :Number = 0.5) :BitmapData {

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
}
}