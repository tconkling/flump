//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flash.filesystem.File;
import flash.utils.ByteArray;
import flash.utils.IDataOutput;

import deng.fzip.FZip;
import deng.fzip.FZipFile;

import flump.display.LibraryLoader;
import flump.xfl.XflLibrary;

public class JSONZipFormat extends PublishFormat
{
    public static const NAME :String = "JSONZip";

    public var outputFile :File;

    public function JSONZipFormat (destDir :File, lib :XflLibrary, conf :ExportConf) {
        super(destDir, lib, conf);
        if (conf.name != null) {
            outputFile = _destDir.resolvePath(conf.name + "/" + lib.location + ".zip");
        } else {
            outputFile = _destDir.resolvePath(lib.location + ".zip");
        }
    }

    override public function get modified () :Boolean {
        if (!outputFile.exists) return true;

        const zip :FZip = new FZip();
        zip.loadBytes(Files.read(outputFile));
        const md5File :FZipFile = zip.getFileByName("md5");
        const md5 :String = md5File.content.readUTFBytes(md5File.content.length);
        return md5 != _lib.md5;
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
        addToZip(LibraryLoader.LIBRARY_LOCATION, function (b :ByteArray) :void {
            b.writeUTFBytes(_lib.toJSONString(atlases, _conf));
        });
        addToZip(LibraryLoader.MD5_LOCATION,
            function (b :ByteArray) :void { b.writeUTFBytes(_lib.md5); });
        addToZip(LibraryLoader.VERSION_LOCATION,
            function (b :ByteArray) :void { b.writeUTFBytes(LibraryLoader.VERSION); });

        Files.write(outputFile, function (out :IDataOutput) :void {
            zip.serialize(out, /*includeAdler32=*/true);
        });
    }

}
}
