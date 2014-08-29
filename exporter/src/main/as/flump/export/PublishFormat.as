//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import aspire.util.Preconditions;

import com.adobe.crypto.MD5;

import flash.filesystem.File;

import flump.mold.LibraryMold;
import flump.mold.MovieMold;
import flump.mold.TextureGroupMold;
import flump.xfl.XflLibrary;

public class PublishFormat
{
    public function PublishFormat (destDir :File, libs :Vector.<XflLibrary>, conf :ExportConf) {
        Preconditions.checkArgument(libs.length > 0, "There must be at least one XflLibrary");
        if (libs.length > 1) {
            var frameRate :Number = libs[0].frameRate;
            for (var ii :int = 1; ii < libs.length; ii++) {
                Preconditions.checkArgument(frameRate == libs[ii].frameRate,
                    "All XflLibraries within a combined publish must use the same framerate");
            }
        }
        _libs = libs;
        _destDir = destDir;
        _conf = conf;
    }

    public function get modified () :Boolean { throw new Error("Must be implemented by a subclass"); }

    public function publish () :void { throw new Error("Must be implemented by a subclass"); }

    protected function get md5 () :String {
        if (_libs.length == 1) return _libs[0].md5;

        // for combined libs, use a hash of the concatenated libs' md5s.
        return MD5.hash(_libs.map(function (lib :XflLibrary, ...ignored) :String {
            return lib.md5;
        }).join("|"))
    }

    protected function get location () :String {
        // for combined libs, use a default name for the resulting export
        return _libs.length == 1 ? _libs[0].location : "flump_combined";
    }

    protected function createAtlases (prefix :String = "") :Vector.<Atlas> {
        const packer :TexturePacker = TexturePacker.withLibs(_libs)
            .baseScale(_conf.scale)
            .borderSize(_conf.textureBorder)
            .maxAtlasSize(_conf.maxAtlasSize)
            .optimizeForSpeed(_conf.optimize == ExportConf.OPTIMIZE_SPEED)
            .quality(_conf.quality)
            .filenamePrefix(prefix);

        var atlases :Vector.<Atlas> = packer.scaleFactor(1).createAtlases(); // 1x atlases

        // additional scales
        for each (var scaleFactor :int in _conf.additionalScaleFactors) {
            atlases = atlases.concat(packer.scaleFactor(scaleFactor).createAtlases());
        }

        return atlases;
    }

    protected function createMold (atlases :Vector.<Atlas>) :LibraryMold {
        const mold :LibraryMold = new LibraryMold();
        mold.frameRate = _libs[0].frameRate; // we already verified all the libs share a framerate
        mold.md5 = md5;
        mold.textureGroups = createTextureGroupMolds(atlases);
        mold.movies = new <MovieMold>[];
        for each (var lib :XflLibrary in _libs) {
            for each (var movie :MovieMold in lib.publishedMovies) {
                mold.movies[mold.movies.length] = movie.scale(_conf.scale);
            }
        }
        return mold;
    }

    protected function toJSONString (mold :LibraryMold) :String {
        return JSON.stringify(mold, null, _conf.prettyPrint ? " " : null);
    }

    /** Creates TextureGroupMolds from a list of Atlases */
    protected static function createTextureGroupMolds (atlases :Vector.<Atlas>) :Vector.<TextureGroupMold> {
        const groups :Vector.<TextureGroupMold> = new <TextureGroupMold>[];
        function getGroup (scaleFactor :int) :TextureGroupMold {
            for each (var group :TextureGroupMold in groups) {
                if (group.scaleFactor == scaleFactor) {
                    return group;
                }
            }
            group = new TextureGroupMold();
            group.scaleFactor = scaleFactor;
            groups.push(group);
            return group;
        }

        for each (var atlas :Atlas in atlases) {
            var group :TextureGroupMold = getGroup(atlas.scaleFactor);
            group.atlases.push(atlas.toMold());
        }

        return groups;
    }

    protected var _libs :Vector.<XflLibrary>;
    protected var _destDir :File;
    protected var _conf :ExportConf;
}
}
