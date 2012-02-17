//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Rectangle;

import com.adobe.images.PNGEncoder;

import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

public class PngPublisher
{
    public static function dumpTextures (base :File, library :XflLibrary) :void {
        for each (var tex :XflTexture in library.textures) {
            const packed :PackedTexture = PackedTexture.fromTexture(tex, library);
            packed.publish(tex.exportPath(base));
            tex.offset = packed.offset;
        }
    }

    public static function renderToBitmapData (target :DisplayObject, width :int, height :int)
            :BitmapData {
        const bd :BitmapData = new BitmapData(width, height, true);
        // Clear bitmapdata's default white background with a transparent one
        bd.fillRect(new Rectangle(0, 0, width, height), 0);
        bd.draw(target);
        return bd;
      }

    public static function publish (dest :File, width :int, height :int,
            target :DisplayObject) :void {
        var bd :BitmapData = renderToBitmapData(target, width, height);
        var fs :FileStream = new FileStream();
        fs.open(dest, FileMode.WRITE);
        fs.writeBytes(PNGEncoder.encode(bd));
        fs.close();
    }
}
}
