//
// Flump - Copyright 2013 Flump Authors

package flump.executor.load {

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;

public class LoadedImage
{
    public function LoadedImage (loader :Loader) {
        _loader = loader;
    }

    public function get bitmap () :Bitmap {
        return (_loader.content as Bitmap);
    }

   public function get bitmapData () :BitmapData {
        return bitmap.bitmapData;
    }

    public function unload () :void {
        try {
            _loader.close();
        } catch (e :Error) {
            // swallow the exception
        }
        _loader.unload();
    }

    protected var _loader :Loader;
}
}
