//
// Flump - Copyright 2013 Flump Authors

package flump.demo {

import flash.display.Sprite;

import starling.core.Starling;

[SWF(width="640", height="480", frameRate="60", backgroundColor="#ffffff")]
public class Demo extends Sprite
{
    public function Demo () {
        _starling = new Starling(DemoScreen, stage);
        _starling.start();
    }

    protected var _starling :Starling;
}
}
