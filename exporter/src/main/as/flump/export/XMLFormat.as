//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;
import flash.utils.IDataOutput;

import flump.bytesToXML;
import flump.mold.MovieMold;
import flump.xfl.XflLibrary;

import com.threerings.util.XmlUtil;

public class XMLFormat extends Format
{
    public function XMLFormat (destDir :File, lib :XflLibrary, conf :ExportConf, maxSize :int) {
        super(destDir, lib, conf, maxSize);
        _prefix = conf.name + "/" + lib.location + "/";
        _metaFile =  _destDir.resolvePath(_prefix + "resources.xml");
    }

    override public function get modified () :Boolean {
        return !_metaFile.exists || bytesToXML(Files.read(_metaFile)).@md5 != _lib.md5;
    }

    override public function publish () :void {
        const libExportDir :File = _destDir.resolvePath(_prefix);
        // Ensure any previously generated atlases don't linger
        if (libExportDir.exists) libExportDir.deleteDirectory(/*deteDirectoryContents=*/true);
        libExportDir.createDirectory();

        const packers :Vector.<Packer> = new <Packer>[
            new Packer(_lib, _conf.scale, _maxSize, _prefix),
            new Packer(_lib, _conf.scale * 2, _maxSize, _prefix, "@2x"),
        ];

        for each (var packer :Packer in packers) {
            for each (var atlas :Atlas in packer.atlases) {
                Files.write(_destDir.resolvePath(atlas.filename), atlas.writePNG);
            }
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
        const groupsXml :XML = <textureGroups/>;
        xml.appendChild(groupsXml);

        function addPacker(packer :Packer, retina :Boolean) :void {
            var groupXml :XML = <textureGroup retina={retina}/>;
            groupsXml.appendChild(groupXml);
            for each (var atlas :Atlas in packer.atlases) {
                groupXml.appendChild(atlas.toMold().toXML());
            }
        }
        addPacker(packers[0], false);
        addPacker(packers[1], true);
        for each (var texture :XML in groupsXml..texture) texture.@name = prefix + texture.@name;

        const xmlString :String = xml.toString();
        Files.write(_metaFile, function (out :IDataOutput) :void { out.writeUTFBytes(xmlString); });
    }


    protected var _prefix :String;
    protected var _metaFile :File;
}
}
