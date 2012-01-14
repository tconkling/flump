//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.geom.Matrix;
import flash.geom.Point;

import flump.xfl.XflKeyframe;
import flump.xfl.XflLayer;
import flump.xfl.XflTexture;

import starling.animation.Tween;
import starling.core.Starling;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

public class Layer extends Sprite
{
    public function Layer (layer :XflLayer, xflTex :XflTexture)
    {
        var initial :XflKeyframe = layer.keyframes[0];
        x = initial.matrix.tx;
        y = initial.matrix.ty;
        var image :Image = new Image(Texture.fromBitmap(xflTex.image.bitmap));
        image.x = xflTex.offset.x;
        image.y = xflTex.offset.y;
        addChild(image);

        for (var ii :int = 1; ii < layer.keyframes.length; ii++) {    
            var mat :Matrix = layer.keyframes[ii].matrix;
            var tween :Tween = new Tween(this, layer.keyframes[ii - 1].duration/30.0);
            tween.moveTo(mat.tx, mat.ty);
            var py :Point = mat.deltaTransformPoint(new Point(1, 0));
            tween.animate("rotation", Math.atan2(py.y, py.x));
            tween.animate("scaleX", Math.sqrt((mat.a * mat.a) + (mat.b * mat.b)));
            tween.animate("scaleY", Math.sqrt((mat.c * mat.c) + (mat.d * mat.d)));
            if (ii == 1) _start = tween;
            else _current.onComplete = function (..._) :void {
                Starling.juggler.add(tween);
                _current = tween;
            };
            _current = tween;
        }
    }

    public function play () :void {
        stop();
        _current = _start;
        Starling.juggler.add(_start);
    }

    public function stop () :void { Starling.juggler.remove(_current); }

    protected var _start :Tween, _current :Tween;
}
}
