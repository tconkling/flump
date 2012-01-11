//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.filesystem.File;

import executor.Executor;

import flump.Image;
import flump.xfl.Library;

import starling.display.Sprite;
import starling.textures.Texture;

public class Preview extends Sprite
{
    public function displayTextures (base :File, lib :Library) :void {
        var loader :Executor = new Executor();
        var x :int = 0;
        for each (var tex :flump.xfl.Texture in lib.textures) {
            new ImageLoader().loadFromFile(tex.exportPath(base), loader).succeeded.add(function (img :Image) :void {
                const starTex :Texture = Texture.fromBitmap(img.bitmap);
                const starImg :starling.display.Image = new starling.display.Image(starTex);
                starImg.x = x;
                x += starImg.width;
                addChild(starImg);
            });
        }
    }
}
}
