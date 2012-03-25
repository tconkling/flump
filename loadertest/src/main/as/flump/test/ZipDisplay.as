//
// Flump - Copyright 2012 Three Rings Design

package flump.test {

import flash.filesystem.File;

import flump.display.Movie;
import flump.display.StarlingResources;

import starling.display.Sprite;

public class ZipDisplay extends Sprite
{
    public function ZipDisplay () {
        // Run the app directory through new File to make a real path out of it. Otherwise it
        // resolves as 'app:/'
        const root :File = new File(File.applicationDirectory.nativePath);
        const resources :File = root.resolvePath('../bella.zip');
        StarlingResources.loadURL(resources.url).succeeded.add(onResourcesLoaded);
    }

    protected function onResourcesLoaded (resources :StarlingResources) :void {
        const movie :Movie = resources.loadMovie("dance_01");
        movie.x = movie.width;
        movie.y = movie.height/2;
        addChild(movie);
    }
}
}
