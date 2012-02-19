//
// Executor - Copyright 2012 Three Rings Design

package flump.executor.load {

import flash.display.Loader;

public class ImageLoader extends BaseLoader
{
    override protected function handleSuccess (onSuccess :Function, loader :Loader) :void {
        onSuccess(new LoadedImage(loader));
    }
}
}
