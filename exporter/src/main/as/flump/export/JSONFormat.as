//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import aspire.util.F;

import flash.filesystem.File;
import flash.utils.ByteArray;
import flash.utils.IDataOutput;

import flump.xfl.XflLibrary;

public class JSONFormat extends PublishFormat
{
    public static const NAME :String = "JSON";

    public static function readJSON (file :File) :Object {
        const bytes :ByteArray = Files.read(file);
        return JSON.parse(bytes.readUTFBytes(bytes.length))
    }

    public function JSONFormat (destDir :File, libs :Vector.<XflLibrary>, conf :ExportConf,
            projectName :String) {
        super(destDir, libs, conf, projectName);
        _prefix = conf.name + "/" + location;
        _metaFile =  _destDir.resolvePath(_prefix + "/library.json");
    }

    override public function get modified () :Boolean {
        if (!_metaFile.exists) return true;
        return readJSON(_metaFile).md5 != md5;
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
                F.bind(AtlasUtil.writePNG, atlas, F._1));
        }

        const json :String = toJSONString(createMold(atlases));
        Files.write(_metaFile, function (out :IDataOutput) :void {  out.writeUTFBytes(json); });
    }

    protected var _prefix :String;
    protected var _metaFile :File;
}
}
