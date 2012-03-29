//
// Flump - Copyright 2012 Three Rings Design

package flump.test {

import flash.utils.ByteArray;

import flump.display.Movie;
import flump.display.StarlingResources;

import starling.display.Sprite;

public class ZipDisplay extends Sprite
{
    public function ZipDisplay () {
        StarlingResources.loadBytes(ByteArray(new BELLA_ZIP())).succeeded.add(onResourcesLoaded);
    }

    protected function onResourcesLoaded (resources :StarlingResources) :void {
        const movie :Movie = resources.loadMovie("dance_01");
        movie.x = movie.width;
        movie.y = movie.height/2;
        addChild(movie);
    }

    [Embed(source="/../../../bella.zip", mimeType="application/octet-stream")]
    private static const BELLA_ZIP :Class;
}
}
