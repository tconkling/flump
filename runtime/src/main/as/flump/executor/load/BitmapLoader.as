//
// Flump - Copyright 2013 Flump Authors

package flump.executor.load {

import flash.display.Bitmap;
import flash.display.Loader;

public class BitmapLoader extends BaseLoader
{
    override protected function handleSuccess (onSuccess :Function, loader :Loader) :void {
        var bitmap :Bitmap = loader.content as Bitmap;
        onSuccess(bitmap.bitmapData);
    }
}
}
