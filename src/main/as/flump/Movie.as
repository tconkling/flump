//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flump.xfl.XflAnimation;
import flump.xfl.XflLayer;

import starling.display.Sprite;

import com.threerings.util.Map;

public class Movie extends Sprite
{
    public function Movie (anim :XflAnimation, xflTextures :Map, textures :Map)
    {
        for each (var layer :XflLayer in anim.layers) {
            _layers.push(new Layer(layer, xflTextures.get(layer.libraryName),
                textures.get(layer.libraryName)));
            addChild(_layers[_layers.length - 1]);
        }
    }

    public function play () :void {
        for each (var layer :Layer in _layers) {
            layer.play();
        }

    }

    public function stop () :void {

    }

    protected const _layers :Vector.<Layer> = new Vector.<Layer>();
}
}
