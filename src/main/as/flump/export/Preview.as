//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.display.BitmapData;
import flash.filesystem.File;

import flump.display.Movie;
import flump.xfl.XflLibrary;
import flump.xfl.XflMovie;
import flump.xfl.XflTexture;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

import com.threerings.display.Animation;

public class Preview extends Sprite
{
    public function displayAnimation (base :File, lib :XflLibrary, xflMovie :XflMovie) :void {
        var movie :Movie = new Movie(xflMovie, function (symbol :String) :DisplayObject {
            const xflTex :XflTexture = lib.lookup(symbol);
            const packed :PackedTexture = PackedTexture.fromTexture(xflTex, lib);
            const image :Image = new Image(Texture.fromBitmapData(packed.toBitmapData()));
            image.x = packed.offset.x;
            image.y = packed.offset.y;
            const holder :Sprite = new Sprite();
            holder.addChild(image);
            return holder;
        });
        addChild(movie);
    }
}
}
