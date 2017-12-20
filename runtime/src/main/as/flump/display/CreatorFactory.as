package flump.display {

import flash.display.BitmapData;
import flash.geom.Point;
import flash.utils.ByteArray;

import flump.mold.AtlasMold;
import flump.mold.AtlasTextureMold;
import flump.mold.MovieMold;

import starling.textures.Texture;

/**
 * A Factory for creating SymbolCreators that is given some context as a Library is assembled.
 */
public interface CreatorFactory {
    /**
     * Load a BitmapData from a ByteArray
     * @param atlas the AtlasMold for this texture atlas
     * @param atlasIndex the index of the AtlasMold in its TextureGroupMold
     * @param bytes the ByteArray from which the BitmapData should be loaded
     * @param onSuccess a function that should be called with the BitmapData on a successful load
     * @param onFailure a function that should be called with an Error (or ErrorEvent or String) if the load fails
     */
    function loadAtlasBitmap (atlas :AtlasMold, atlasIndex :int, bytes :ByteArray, onSuccess :Function, onFailure :Function) :void;

    function createTextureFromBitmap (atlas :AtlasMold, bitmapData :BitmapData, scale :Number, generateMipMaps :Boolean) :Texture;

    function createImageCreator (mold :AtlasTextureMold, texture :Texture, origin :Point,
        symbol :String) :ImageCreator;

    function createMovieCreator (mold :MovieMold, frameRate :Number) :MovieCreator;

    function consumingAtlasMold (mold :AtlasMold) :void;
}
}
