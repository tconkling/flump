package flump.display {

import flash.display.BitmapData;
import flash.geom.Point;

import flump.mold.AtlasMold;
import flump.mold.AtlasTextureMold;
import flump.mold.MovieMold;

import starling.textures.Texture;

/**
 * A Factory for creating SymbolCreators that is given some context as a Library is assembled.
 */
public interface CreatorFactory {
    function createTextureFromBitmap (atlas :AtlasMold, bitmapData :BitmapData, scale :Number, generateMipMaps :Boolean) :Texture;

    function createImageCreator (mold :AtlasTextureMold, texture :Texture, origin :Point,
        symbol :String) :ImageCreator;

    function createMovieCreator (mold :MovieMold, frameRate :Number) :MovieCreator;

    function consumingAtlasMold (mold :AtlasMold) :void;
}
}
