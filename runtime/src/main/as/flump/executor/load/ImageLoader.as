//
// Flump - Copyright 2013 Flump Authors

package flump.executor.load {

import flash.display.Loader;

public class ImageLoader extends BaseLoader
{
    override protected function handleSuccess (onSuccess :Function, loader :Loader) :void {
        onSuccess(new LoadedImage(loader));
    }
}
}
