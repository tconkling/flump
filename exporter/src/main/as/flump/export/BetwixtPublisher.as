//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import com.threerings.util.Log;
import com.threerings.util.Map;
import com.threerings.util.Maps;
import com.threerings.util.XmlUtil;

import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;

import flump.bytesToXML;
import flump.xfl.XflLibrary;
import flump.xfl.XflMovie;
import flump.xfl.XflTexture;

public class BetwixtPublisher
{
    public static function modified(lib :XflLibrary, exportDir :File) :Boolean {
        const exportLoc :File = exportDir.resolvePath(lib.location + "/resources.xml");
        if (!exportLoc.exists) return true;

        const libMd5s :Map = Maps.newMapOf(String);
        for each (var movie :XflMovie in lib.movies) libMd5s.put(movie.libraryItem, movie.md5);
        for each (var tex :XflTexture in lib.textures) libMd5s.put(tex.libraryItem, tex.md5);

        const exportMd5s :Map = Maps.newMapOf(String);
        var export :FileStream = new FileStream();
        export.open(exportLoc, FileMode.READ);
        var exportBytes :ByteArray = new ByteArray();
        export.readBytes(exportBytes);
        export.close();
        var xml :XML = bytesToXML(exportBytes);
        function addMd5(el :XML) :void {
            exportMd5s.put(XmlUtil.getStringAttr(el, "name"), XmlUtil.getStringAttr(el, "md5"));
        };
        // Add md5s one and two levels deep in the resource xml
        for each (var res :XML in xml.*.(hasOwnProperty('@md5'))) addMd5(res);
        for each (res in xml.*.*.(hasOwnProperty('@md5'))) addMd5(res);
        return !exportMd5s.equals(libMd5s);
    }

    public static function publish (lib :XflLibrary, source :File, exportDir :File) :void {
        var packers :Array = [
            new Packer(DeviceType.IPHONE_RETINA, lib),
            new Packer(DeviceType.IPHONE, lib)
        ];

        const destDir :File = exportDir.resolvePath(lib.location);
        destDir.createDirectory();

        for each (var packer :Packer in packers) {
            for each (var atlas :Atlas in packer.atlases) {
                atlas.publish(exportDir);
            }
        }

        // TODO(bruno): Remove this encoder
        /*var dest :File = destDir.resolvePath("resources.xml");
        var out :FileStream = new FileStream();
        out.open(dest, FileMode.WRITE);
        out.writeUTFBytes("<resources>\n");
        for each (var movie :XflMovie in lib.movies) {
            out.writeUTFBytes('  <movie name="' + movie.libraryItem + '" md5="' + movie.md5 + '">\n');

            var movieFile :File = source.resolvePath("LIBRARY/" + movie.libraryItem + ".xml");
            var copy :FileStream = new FileStream();
            copy.open(movieFile, FileMode.READ);
            var bytes :ByteArray = new ByteArray();
            copy.readBytes(bytes);
            out.writeBytes(bytes);
            out.writeUTFBytes('\n  </movie>\n');
        }
        for each (atlas in packer.atlases) out.writeUTFBytes(atlas.toXml());
        out.writeUTFBytes("</resources>");
        out.close();*/

        publishMetadata(lib, packers, destDir.resolvePath("resources-new.xml"));
        publishMetadata(lib, packers, destDir.resolvePath("resources.json"));
    }

    protected static function publishMetadata (lib :XflLibrary, packers :Array, dest :File) :void {
        var out :FileStream = new FileStream();
        out.open(dest, FileMode.WRITE);

        var url :String = dest.url;
        var format :String = url.substr(url.lastIndexOf(".") + 1).toLowerCase();
        switch (format) {
        case "xml":
            var xml :XML = <resources/>;
            for each (var movie :XflMovie in lib.movies) {
                xml.appendChild(movie.toXML());
            }
            var groupsXml :XML = <textureGroups/>;
            xml.appendChild(groupsXml);
            for each (var packer :Packer in packers) {
                var groupXml :XML = <textureGroup target={packer.targetDevice}/>;
                groupsXml.appendChild(groupXml);
                for each (var atlas :Atlas in packer.atlases) {
                    groupXml.appendChild(atlas.toXML());
                }
            }
            out.writeUTFBytes(xml.toString());
            break;

        case "json":
            var json :Object = {
                movies: lib.movies,
                atlases: packers[0].atlases
            };
            var pretty :Boolean = false;
            out.writeUTFBytes(JSON.stringify(json, null, pretty ? "  " : null));
            break;
        }

        out.close();
    }

    private static const log :Log = Log.getLog(BetwixtPublisher);
}
}
