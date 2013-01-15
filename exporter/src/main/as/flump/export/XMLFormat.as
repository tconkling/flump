//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flash.filesystem.File;
import flash.utils.IDataOutput;

import flump.Util;
import flump.mold.LibraryMold;
import flump.mold.MovieMold;
import flump.mold.TextureGroupMold;
import flump.xfl.XflLibrary;

import com.threerings.util.F;
import com.threerings.util.XmlUtil;

public class XMLFormat extends PublishFormat
{
    public static const NAME :String = "XML";

    public function XMLFormat (destDir :File, lib :XflLibrary, conf :ExportConf) {
        super(destDir, lib, conf);
        _prefix = conf.name + "/" + lib.location + "/";
        _metaFile =  _destDir.resolvePath(_prefix + "resources.xml");
    }

    override public function get modified () :Boolean {
        return !_metaFile.exists || Util.bytesToXML(Files.read(_metaFile)).@md5 != _lib.md5;
    }

    override public function publish () :void {
        const libExportDir :File = _destDir.resolvePath(_prefix);
        // Ensure any previously generated atlases don't linger
        if (libExportDir.exists) libExportDir.deleteDirectory(/*deleteDirectoryContents=*/true);
        libExportDir.createDirectory();

        const atlases :Vector.<Atlas> = createAtlases(_prefix);
        for each (var atlas :Atlas in atlases) {
            Files.write(
                _destDir.resolvePath(atlas.filename),
                F.partial(AtlasUtil.writePNG, atlas, F._1));
        }

        const xml :XML = <resources md5={_lib.md5}/>;
        const prefix :String = _lib.location + "/";
        for each (var movie :MovieMold in _lib.publishedMovies) {
            var movieXml :XML = movie.scale(_conf.scale).toXML();
            movieXml.@name = prefix + movieXml.@name;
            movieXml.@frameRate = _lib.frameRate;
            for each (var kf :XML in movieXml..kf) {
                if (XmlUtil.hasAttr(kf, "ref")) kf.@ref = prefix + kf.@ref;
            }
            xml.appendChild(movieXml);
        }

        const libraryMold :LibraryMold = _lib.toMold(atlases, _conf);
        const groupsXml :XML = <textureGroups/>;
        xml.appendChild(groupsXml);
        for each (var group :TextureGroupMold in libraryMold.textureGroups) {
            groupsXml.appendChild(group.toXML());
        }

        for each (var texture :XML in groupsXml..texture) texture.@name = prefix + texture.@name;

        const xmlString :String = xml.toString();
        Files.write(_metaFile, function (out :IDataOutput) :void { out.writeUTFBytes(xmlString); });
    }


    protected var _prefix :String;
    protected var _metaFile :File;
}
}
