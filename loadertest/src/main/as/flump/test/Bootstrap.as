//
// Flump - Copyright 2012 Three Rings Design

package flump.test {

import flash.display.Sprite;

import starling.core.Starling;

[SWF(width="640", height="480", frameRate="60", backgroundColor="#ffffff")]
public class Bootstrap extends Sprite
{
    public function Bootstrap () {
        _starling = new Starling(ZipDisplay, stage);
        _starling.start();
    }

    protected var _starling :Starling;
}
}
