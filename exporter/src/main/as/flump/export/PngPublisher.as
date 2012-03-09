//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import com.adobe.images.PNGEncoder;

import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;

import flump.SwfTexture;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

public class PngPublisher
{
    public static function dumpTextures (base :File, library :XflLibrary) :void {
        for each (var tex :XflTexture in library.textures) {
            const packed :SwfTexture = SwfTexture.fromTexture(library.swf, tex);
            publish(base.resolvePath(tex.symbol + ".png"), packed.w, packed.h, packed.holder);
        }
    }

    public static function publish (dest :File, width :int, height :int, target :DisplayObject) :void {
        var bd :BitmapData = SwfTexture.renderToBitmapData(target, width, height);
        var fs :FileStream = new FileStream();
        fs.open(dest, FileMode.WRITE);
        fs.writeBytes(PNGEncoder.encode(bd));
        fs.close();
    }
}
}
