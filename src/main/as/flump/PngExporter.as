//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.display.BitmapData;
import flash.display.Sprite;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Point;
import flash.geom.Rectangle;

import com.adobe.images.PNGEncoder;

import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

public class PngExporter
{

    public static function dumpTextures (base :File, library :XflLibrary) :void {
        for each (var tex :XflTexture in library.textures) {
            var klass :Class = library.swf.getSymbol(tex.symbol) as Class;
            var sprite :Sprite = (new klass()) as Sprite;
            tex.offset = export(tex.exportPath(base), sprite);
        }
    }

    public static function export (dest :File, toExport :Sprite) :Point {
        const holder :Sprite = new Sprite();
        holder.addChild(toExport);
        const bounds :Rectangle = toExport.getBounds(holder);
        toExport.x = -bounds.x;
        toExport.y = -bounds.y;

        const bd :BitmapData = new BitmapData(bounds.width, bounds.height, true);
        // Clear bitmapdata's default white background with a transparent one
        bd.fillRect(new Rectangle(0, 0, bounds.width, bounds.height), 0);
        bd.draw(holder);
        var fs :FileStream = new FileStream();
        fs.open(dest, FileMode.WRITE);
        fs.writeBytes(PNGEncoder.encode(bd));
        fs.close();
        return new Point(bounds.x, bounds.y);
    }
}
}
