//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;

import flump.xfl.XflLibrary;

import com.threerings.util.Log;

public class Publisher
{
    public function Publisher(exportDir :File, format :Format, ...formats) {
        _exportDir = exportDir;
        _formats.push(format);
        for each (format in formats) _formats.push(format);
    }

    public function modified (lib :XflLibrary) :Boolean {
        const destDir :File = _exportDir.resolvePath(lib.location);
        for each (var format :Format in _formats) {
            var metadata :File = format.getMetadata(destDir);
            if (!metadata.exists) return true;

            var stream :FileStream = new FileStream();
            stream.open(metadata, FileMode.READ);
            var bytes :ByteArray = new ByteArray();
            stream.readBytes(bytes);
            stream.close();


            try {
                if (format.extractMd5(bytes) != lib.md5) return true;
            } catch (e :Error) {
                log.warning("Hit exception parsing existing metadata; calling it modified", e);
                return true;
            }
        }
        return false;
    }

    public function publish (lib :XflLibrary, authoredDevice :DeviceType) :void {
        var packers :Vector.<Packer> = new <Packer>[
            new Packer(DeviceType.IPHONE_RETINA, authoredDevice, lib),
            new Packer(DeviceType.IPHONE, authoredDevice, lib)
        ];

        const destDir :File = _exportDir.resolvePath(lib.location);
        destDir.createDirectory();

        // Ensure any previously generated atlases don't linger
        for each (var file :File in destDir.getDirectoryListing()) {
            if (file.name.match(/atlas.*\.png/)) file.deleteFile();
        }

        for each (var packer :Packer in packers) {
            for each (var atlas :Atlas in packer.atlases) {
                atlas.publish(_exportDir);
            }
        }
        for each (var format :Format in _formats) {
            var out :FileStream = new FileStream();
            out.open(format.getMetadata(destDir), FileMode.WRITE);

            format.publish(out, lib, packers, authoredDevice);
            out.close();
        }
    }

    private var _exportDir :File;
    private const _formats :Vector.<Format> = new Vector.<Format>();
    private static const log :Log = Log.getLog(Publisher);
}
}
