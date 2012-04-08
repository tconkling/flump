//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.utils.ByteArray;
import flash.utils.IDataOutput;

import deng.fzip.FZip;
import deng.fzip.FZipFile;

import flump.display.StarlingResources;
import flump.xfl.XflLibrary;

public class StarlingFormat extends Format
{
    public function StarlingFormat () {
        super("resources-starling.zip");
    }

    override public function extractMd5 (metadata :ByteArray) :String {
        const zip :FZip = new FZip();
        zip.loadBytes(metadata);
        const md5File :FZipFile = zip.getFileByName("md5");
        return md5File.content.readUTFBytes(md5File.content.length);
    }

    override public function publish(out :IDataOutput, lib :XflLibrary, packers :Vector.<Packer>,
        authoredDevice :DeviceType) :void {
        const zip :FZip = new FZip();

        function addToZip(name :String, contentWriter :Function) :void {
            const bytes :ByteArray = new ByteArray();
            contentWriter(bytes);
            zip.addFile(name, bytes);
        }

        for each (var atlas :Atlas in packers[0].atlases) {
            addToZip(atlas.fileName, function (b :ByteArray) :void { atlas.writePNG(b); });
        }
        addToZip(StarlingResources.LIBRARY_LOCATION,
            function (b :ByteArray) :void { b.writeUTFBytes(lib.toJSONString(packers[0].atlases)); });
        addToZip(StarlingResources.MD5_LOCATION,
            function (b :ByteArray) :void { b.writeUTFBytes(lib.md5); });

        zip.serialize(out, /*includeAdler32=*/true);
    }
}
}
