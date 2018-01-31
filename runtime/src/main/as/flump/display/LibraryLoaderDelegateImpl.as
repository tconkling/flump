package flump.display {

import flash.display.BitmapData;
import flash.geom.Point;
import flash.utils.ByteArray;

import flump.executor.Future;
import flump.executor.load.BitmapLoader;
import flump.mold.AtlasMold;
import flump.mold.AtlasTextureMold;
import flump.mold.MovieMold;

import starling.textures.Texture;

/**
 * A default implementation of LibraryLoaderDelegate, it does nothing but return vanilla ImageCreators and
 * MovieCreators. It may be used as an adapter super class for a custom LibraryLoaderDelegate
 * implementation.
 */
internal class LibraryLoaderDelegateImpl implements LibraryLoaderDelegate {
    public function loadAtlasBitmap (atlas :AtlasMold, atlasIndex :int, bytes :ByteArray, onSuccess :Function, onError :Function) :void {
        if (_bitmapLoader == null) {
            _bitmapLoader = new BitmapLoader();
        }
        var f :Future = _bitmapLoader.loadFromBytes(bytes);
        f.succeeded.connect(onSuccess);
        f.failed.connect(onError);
    }

    public function createTextureFromBitmap (atlas :AtlasMold, bitmapData :BitmapData,
        scale :Number, generateMipMaps :Boolean) :Texture {

        return Texture.fromBitmapData(bitmapData, generateMipMaps, false, scale);
    }

    public function createImageCreator (mold :AtlasTextureMold, texture :Texture, origin :Point,
        symbol :String) :ImageCreator {
        return new ImageCreator(texture, origin, symbol);
    }

    public function createMovieCreator (mold :MovieMold, frameRate :Number) :MovieCreator {
        return new MovieCreator(mold, frameRate);
    }

    public function consumingAtlasMold (mold :AtlasMold) :void { /* nada */ }

    private var _bitmapLoader :BitmapLoader;
}
}
