//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;
import flash.utils.ByteArray;
import flash.utils.IDataOutput;

import flump.xfl.XflLibrary;

public class JSONFormat extends Format
{
    public function JSONFormat (destDir :File, lib :XflLibrary, conf :ExportConf) {
        super(destDir, lib, conf);
        _prefix = conf.directory + "/" + lib.location;
        _metaFile =  _destDir.resolvePath(_prefix + "/resources.json");
    }

    override public function get modified () :Boolean {
        if (!_metaFile.exists) return true;
        const metadata :ByteArray = Files.read(_metaFile);
        return JSON.parse(metadata.readUTFBytes(metadata.length)).md5 != _lib.md5;
    }

    override public function publish () :void {
        const libExportDir :File = _destDir.resolvePath(_prefix);
        // Ensure any previously generated atlases don't linger
        if (libExportDir.exists) libExportDir.deleteDirectory(/*deteDirectoryContents=*/true);
        libExportDir.createDirectory();

        const packer :Packer = new Packer(_lib, _conf.scale, _prefix);
        for each (var atlas :Atlas in packer.atlases) {
            Files.write(_destDir.resolvePath(atlas.filename), atlas.writePNG);
        }
        const json :String = _lib.toJSONString(packer.atlases, _conf.scale);
        Files.write(_metaFile, function (out :IDataOutput) :void {  out.writeUTFBytes(json); });
    }

    protected var _prefix :String;
    protected var _metaFile :File;
}
}
