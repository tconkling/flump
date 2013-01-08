//
// Flump - Copyright 2012 Three Rings Design

package flump.demo {

import flash.display.Sprite;

import starling.core.Starling;

[SWF(width="640", height="480", frameRate="60", backgroundColor="#ffffff")]
public class Bootstrap extends Sprite
{
    public function Bootstrap () {
        _starling = new Starling(DemoScreen, stage);
        _starling.start();
    }

    protected var _starling :Starling;
}
}
