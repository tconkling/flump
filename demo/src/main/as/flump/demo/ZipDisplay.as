//
// Flump - Copyright 2012 Three Rings Design

package flump.demo {

import flash.utils.ByteArray;

import flump.display.Movie;
import flump.display.StarlingResources;
import flump.executor.Future;

import starling.display.Sprite;

public class ZipDisplay extends Sprite
{
    public function ZipDisplay () {
        const loader :Future = StarlingResources.loadBytes(ByteArray(new BELLA_ZIP()));
        loader.succeeded.add(onResourcesLoaded);
        loader.failed.add(function (e :Error) :void { throw e; });
    }

    protected function onResourcesLoaded (resources :StarlingResources) :void {
        addChild(resources.loadMovie("dance_scene"));
    }

    [Embed(source="/bella.zip", mimeType="application/octet-stream")]
    private static const BELLA_ZIP :Class;
}
}
