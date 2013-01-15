//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flash.filesystem.File;
import flash.utils.ByteArray;
import flash.utils.IDataOutput;

import flump.xfl.XflLibrary;

import com.threerings.util.F;

public class JSONFormat extends PublishFormat
{
    public static const NAME :String = "JSON";

    public static function readJSON (file :File) :Object {
        const bytes :ByteArray = Files.read(file);
        return JSON.parse(bytes.readUTFBytes(bytes.length))
    }

    public function JSONFormat (destDir :File, lib :XflLibrary, conf :ExportConf) {
        super(destDir, lib, conf);
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
        if (libExportDir.exists) libExportDir.deleteDirectory(/*deleteDirectoryContents=*/true);
        libExportDir.createDirectory();

        const atlases :Vector.<Atlas> = createAtlases();
        for each (var atlas :Atlas in atlases) {
            Files.write(
                libExportDir.resolvePath(atlas.filename),
                F.partial(AtlasUtil.writePNG, atlas, F._1));
        }

        const json :String = _lib.toJSONString(atlases, _conf);
        Files.write(_metaFile, function (out :IDataOutput) :void {  out.writeUTFBytes(json); });
    }

    protected var _prefix :String;
    protected var _metaFile :File;
}
}
