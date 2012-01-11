//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.filesystem.File;

import executor.Executor;
import executor.load.ImageLoader;
import executor.load.LoadedImage;

import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

public class Preview extends Sprite
{
    public function displayTextures (base :File, lib :XflLibrary) :void {
        var loader :Executor = new Executor();
        var x :int = 0;
        for each (var tex :XflTexture in lib.textures) {
            new ImageLoader().loadFromUrl(tex.exportPath(base).url, loader).succeeded.add(function (img :LoadedImage) :void {
                const starTex :Texture = Texture.fromBitmap(img.bitmap);
                const starImg :Image = new Image(starTex);
                starImg.x = x;
                x += starImg.width;
                addChild(starImg);
            });
        }
    }
}
}
