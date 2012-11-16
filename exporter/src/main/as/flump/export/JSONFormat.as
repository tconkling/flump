//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;
import flash.utils.ByteArray;
import flash.utils.IDataOutput;

import flump.xfl.XflLibrary;

public class JSONFormat extends Format
{
    public static function readJSON (file :File) :Object {
        const bytes :ByteArray = Files.read(file);
        return JSON.parse(bytes.readUTFBytes(bytes.length))
    }

    public function JSONFormat (destDir :File, lib :XflLibrary, conf :ExportConf, maxSize :int) {
        super(destDir, lib, conf, maxSize);
        _prefix = conf.name + "/" + lib.location;
        _metaFile =  _destDir.resolvePath(_prefix + "/library.json");
    }

    override public function get modified () :Boolean {
        if (!_metaFile.exists) return true;
        return readJSON(_metaFile).md5 != _lib.md5;
    }

    override public function publish () :void {
        const libExportDir :File = _destDir.resolvePath(_prefix);
        // Ensure any previously generated atlases don't linger
        if (libExportDir.exists) libExportDir.deleteDirectory(/*deteDirectoryContents=*/true);
        libExportDir.createDirectory();

        const packer :TexturePacker = new TexturePacker(_lib, _conf.scale, _conf.textureBorder, _maxSize);
        for each (var atlas :Atlas in packer.atlases) {
            Files.write(libExportDir.resolvePath(atlas.filename), atlas.writePNG);
        }
        const json :String = _lib.toJSONString(packer.atlases, _conf.scale);
        Files.write(_metaFile, function (out :IDataOutput) :void {  out.writeUTFBytes(json); });
    }

    protected var _prefix :String;
    protected var _metaFile :File;
}
}
