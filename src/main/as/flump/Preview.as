//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.filesystem.File;
import flash.geom.Matrix;
import flash.geom.Point;

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
                var xflTex :XflTexture = _textures.get(initial.libraryName);
                var holder :Sprite = new Sprite();
                holder.x = initial.matrix.tx;
                holder.y = initial.matrix.ty;
                addChild(holder);
                var image :Image = new Image(Texture.fromBitmap(xflTex.image.bitmap));
                image.x = xflTex.offset.x;
                image.y = xflTex.offset.y;
                holder.addChild(image);

                var tween :Tween = new Tween(holder, 1);
                var mat :Matrix = layer.keyframes[1].matrix;
                tween.moveTo(mat.tx, mat.ty);
                var py :Point = mat.deltaTransformPoint(new Point(1, 0));
                tween.animate("rotation", Math.atan2(py.y, py.x));
                tween.animate("scaleX", Math.sqrt((mat.a * mat.a) + (mat.b * mat.b)));
                tween.animate("scaleY", Math.sqrt((mat.c * mat.c) + (mat.d * mat.d)));
                Starling.juggler.add(tween);
            }
        });
    }

    public function loadTextures (base :File, lib :XflLibrary, onLoaded :Function) :void {
        var loader :Executor = new Executor();
        for each (var tex :XflTexture in lib.textures) {
            if (_textures.containsKey(tex.name)) continue;
            new ImageLoader().loadFromUrl(tex.exportPath(base).url, loader).succeeded.add(
                textureAdder(tex));
        }
        loader.terminated.add(function (..._) :void { onLoaded(); });
        loader.shutdown();
    }

    public function textureAdder (tex :XflTexture) :Function {
        return function (img :LoadedImage) :void {
            tex.image = img;
            _textures.put(tex.name, tex);
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
