//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.filesystem.File;
import flash.geom.Matrix;

import executor.Executor;
import executor.load.ImageLoader;
import executor.load.LoadedImage;

import flump.xfl.XflAnimation;
import flump.xfl.XflKeyframe;
import flump.xfl.XflLayer;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

import starling.animation.Tween;
import starling.core.Starling;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

import com.threerings.util.Map;
import com.threerings.util.Maps;

public class Preview extends Sprite
{
    public function displayAnimation (base :File, lib :XflLibrary, anim :XflAnimation) :void {
        loadTextures(base, lib, function (..._) :void {
            for each (var layer :XflLayer in anim.layers) {
                var initial :XflKeyframe = layer.keyframes[0];
                var image :Image = new Image(_textures.get(initial.libraryName));
                image.pivotX = initial.transformationPoint.x;
                image.pivotY = initial.transformationPoint.y;
                image.x = initial.matrix.tx;
                image.y = initial.matrix.ty;
                var tween :Tween = new Tween(image, 1);
                var complete :XflKeyframe = layer.keyframes[1];
                var mat :Matrix = complete.matrix;
                tween.moveTo(mat.tx, mat.ty);
                tween.animate("rotation", Math.atan( -mat.c / mat.a));
                tween.animate("scaleX", Math.sqrt((mat.a * mat.a) + (mat.c * mat.c)));
                tween.animate("scaleY", Math.sqrt((mat.b * mat.b) + (mat.d * mat.d)));
                Starling.juggler.add(tween);
                addChild(image);
            }
        });
    }

    public function loadTextures (base :File, lib :XflLibrary, onLoaded :Function) :void {
        var loader :Executor = new Executor();
        for each (var tex :XflTexture in lib.textures) {
            if (_textures.containsKey(tex.name)) continue;
            new ImageLoader().loadFromUrl(tex.exportPath(base).url, loader).succeeded.add(
                textureAdder(tex.name));
        }
        loader.terminated.add(function (..._) :void { onLoaded(); });
        loader.shutdown();
    }

    public function textureAdder (name :String) :Function {
        return function (img :LoadedImage) :void {
            _textures.put(name, Texture.fromBitmap(img.bitmap));
        };
    }

    public function displayTextures (base :File, lib :XflLibrary) :void {
        loadTextures(base, lib, function (..._) :void {
            var x :int = 0;
            for each (var tex :Texture in _textures.values()) {
                var img :Image = new Image(tex);
                img.x = x;
                x += img.width;
                addChild(img);
            }
        });
    }

    protected const _textures :Map = Maps.newMapOf(String);
}
}
