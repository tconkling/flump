//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flash.display.StageQuality;

import flump.xfl.XflLibrary;

/**
 * Creates texture atlases from an XflLibrary
 */
public class TexturePacker
{
    public static function withLib (lib :XflLibrary) :TexturePacker {
        return withLibs(new <XflLibrary>[lib]);
    }

    public static function withLibs (libs :Vector.<XflLibrary>) :TexturePacker {
        return new TexturePacker(libs);
    }

    public function baseScale (val :Number) :TexturePacker { _baseScale = val; return this; }
    public function scaleFactor (val :int) :TexturePacker {  _scaleFactor = val; return this; }
    public function borderSize (val :int) :TexturePacker { _borderSize = val; return this; }
    public function maxAtlasSize (val :int) :TexturePacker { _maxAtlasSize = val; return this; }
    public function quality (val :String) :TexturePacker { _quality = val; return this; }
    public function filenamePrefix (val :String) :TexturePacker { _filenamePrefix = val; return this; }

    public function createAtlases () :Vector.<Atlas> {
        return new MaxRectPacker(_libs, _baseScale, _scaleFactor, _borderSize,
            _maxAtlasSize, _quality, _filenamePrefix).atlases;
    }

    /** @private */
    public function TexturePacker (libs :Vector.<XflLibrary>) {
        _libs = libs;
    }

    protected var _libs :Vector.<XflLibrary>;
    protected var _baseScale :Number = 1;
    protected var _scaleFactor :int = 1;
    protected var _borderSize :int = 1;
    protected var _maxAtlasSize :int = 2048;
    protected var _filenamePrefix :String = "";
    protected var _quality :String = StageQuality.BEST;
}
}