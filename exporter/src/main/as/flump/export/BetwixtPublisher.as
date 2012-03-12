//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;

import flump.bytesToXML;
import flump.xfl.XflLibrary;
import flump.xfl.XflMovie;

import com.threerings.util.Log;

public class BetwixtPublisher
{
    public static function modified (lib :XflLibrary, metadata :File) :Boolean
    {
        if (!metadata.exists) return true;

        var stream :FileStream = new FileStream();
        stream.open(metadata, FileMode.READ);
        var bytes :ByteArray = new ByteArray();
        stream.readBytes(bytes);

        var md5 :String = null;
        switch (Files.getExtension(metadata)) {
        case "xml":
            var xml :XML = bytesToXML(bytes);
            md5 = xml.@md5;
            break;

        case "json":
            var json :Object = JSON.parse(bytes.readUTFBytes(bytes.length));
            md5 = json.md5;
            break;
        }

        return md5 != lib.md5;
    }

    public static function publish (lib :XflLibrary, source: File, authoredDevice :DeviceType,
        exportDir :File) :void {
        var packers :Array = [
            new Packer(DeviceType.IPHONE_RETINA, authoredDevice, lib),
            new Packer(DeviceType.IPHONE, authoredDevice, lib)
        ];

        const destDir :File = exportDir.resolvePath(lib.location);
        destDir.createDirectory();

        for each (var packer :Packer in packers) {
            for each (var atlas :Atlas in packer.atlases) {
                atlas.publish(exportDir);
            }
        }

        publishMetadata(lib, packers, authoredDevice, destDir.resolvePath("resources.xml"));
        publishMetadata(lib, packers, authoredDevice, destDir.resolvePath("resources.json"));
    }

    protected static function publishMetadata (lib :XflLibrary, packers :Array,
        authoredDevice :DeviceType, dest :File) :void {
        var out :FileStream = new FileStream();
        out.open(dest, FileMode.WRITE);

        switch (Files.getExtension(dest)) {
        case "xml":
            var xml :XML = <resources md5={lib.md5}/>;
            var prefix :String = lib.location + "/";
            for each (var movie :XflMovie in lib.movies) {
                var movieXml :XML = movie.toXML();
                movieXml.@authoredDevice = authoredDevice.name();
                movieXml.@name = prefix + movieXml.@name;
                for each (var kf :XML in movieXml..kf) {
                    kf.@ref = prefix + kf.@ref;
                }
                xml.appendChild(movieXml);
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
            for each (var texture :XML in groupsXml..texture) {
                texture.@name = prefix + texture.@name;
            }
            out.writeUTFBytes(xml.toString());
            break;

        case "json":
            var json :Object = {
                md5: lib.md5,
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
