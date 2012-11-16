//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;
import flash.utils.ByteArray;
import flash.utils.IDataOutput;

import deng.fzip.FZip;
import deng.fzip.FZipFile;

import flump.display.StarlingResources;
import flump.xfl.XflLibrary;

public class StarlingFormat extends Format
{
    public var outputFile :File;

    public function StarlingFormat (destDir :File, lib :XflLibrary, conf :ExportConf) {
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

        const packer :TexturePacker =
            new TexturePacker(_lib, _conf.scale, _conf.textureBorder, _conf.maxAtlasSize);

        for each (var atlas :Atlas in packer.atlases) {
            addToZip(atlas.filename, function (b :ByteArray) :void { atlas.writePNG(b); });
        }
        addToZip(StarlingResources.LIBRARY_LOCATION, function (b :ByteArray) :void {
            b.writeUTFBytes(_lib.toJSONString(packer.atlases, _conf.scale));
        });
        addToZip(StarlingResources.MD5_LOCATION,
            function (b :ByteArray) :void { b.writeUTFBytes(_lib.md5); });
        addToZip(StarlingResources.VERSION_LOCATION,
            function (b :ByteArray) :void { b.writeUTFBytes(StarlingResources.VERSION); });

        Files.write(outputFile, function (out :IDataOutput) :void {
            zip.serialize(out, /*includeAdler32=*/true);
        });
    }

}
}
