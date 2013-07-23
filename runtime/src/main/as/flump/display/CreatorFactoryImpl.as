package flump.display {

import flash.geom.Point;

import flump.mold.AtlasMold;
import flump.mold.AtlasTextureMold;
import flump.mold.MovieMold;

import starling.textures.Texture;

/**
 * A default implementation of CreatorFactory, it does nothing but return vanilla ImageCreators and
 * MovieCreators. It may be used as an adapter super class for a custom CreatorFactory
 * implementation.
 */
internal class CreatorFactoryImpl implements CreatorFactory {
    public function createImageCreator (mold :AtlasTextureMold, texture :Texture, origin :Point,
        symbol :String) :ImageCreator {
        return new ImageCreator(texture, origin, symbol);
    }

    public function createMovieCreator (mold :MovieMold, frameRate :Number) :MovieCreator {
        return new MovieCreator(mold, frameRate);
    }

    public function consumingAtlasMold (mold :AtlasMold) :void { /* nada */ }
}
}
