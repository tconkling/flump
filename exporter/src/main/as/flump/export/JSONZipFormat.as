//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import deng.fzip.FZip;
import deng.fzip.FZipFile;

import flash.filesystem.File;
import flash.utils.ByteArray;
import flash.utils.IDataOutput;

import flump.FlumpCodes;
import flump.xfl.XflLibrary;

public class JSONZipFormat extends PublishFormat
{
    public static const NAME :String = "JSONZip";

    public function JSONZipFormat (destDir :File, libs :Vector.<XflLibrary>, conf :ExportConf,
            projectName :String) {
        super(destDir, libs, conf, projectName);
        if (conf.name != null) {
            _outputFile = _destDir.resolvePath(conf.name + "/" + location + ".zip");
        } else {
            _outputFile = _destDir.resolvePath(location + ".zip");
        }
    }

    override public function get outputFile () :File {
        return _outputFile;
    }

    override public function get modified () :Boolean {
        if (!_outputFile.exists) return true;

        const zip :FZip = new FZip();
        zip.loadBytes(Files.read(_outputFile));
        const md5File :FZipFile = zip.getFileByName("md5");
        const md5 :String = md5File.content.readUTFBytes(md5File.content.length);
        return md5 != this.md5;
    }

    override public function publish() :void {
        const zip :FZip = new FZip();

        function addToZip(name :String, contentWriter :Function) :void {
            const bytes :ByteArray = new ByteArray();
            contentWriter(bytes);
            zip.addFile(name, bytes);
        }

        const atlases :Vector.<Atlas> = createAtlases();
        for each (var atlas :Atlas in atlases) {
            addToZip(atlas.filename, function (b :ByteArray) :void { AtlasUtil.writePNG(atlas, b); });
        }
        addToZip(FlumpCodes.LIBRARY_FILENAME, function (b :ByteArray) :void {
            b.writeUTFBytes(toJSONString(createMold(atlases)));
        });
        addToZip(FlumpCodes.MD5_FILENAME,
            function (b :ByteArray) :void { b.writeUTFBytes(md5); });
        addToZip(FlumpCodes.VERSION_FILENAME,
            function (b :ByteArray) :void { b.writeUTFBytes(FlumpCodes.JSON_ZIP_VERSION); });

        Files.write(_outputFile, function (out :IDataOutput) :void {
            zip.serialize(out, /*includeAdler32=*/true);
        });
    }

    protected var _outputFile :File;

}
}
