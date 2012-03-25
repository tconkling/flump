//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.utils.ByteArray;
import flash.utils.IDataOutput;

import deng.fzip.FZip;
import deng.fzip.FZipFile;

import flump.display.StarlingResources;
import flump.mold.AtlasMold;
import flump.mold.Molds;
import flump.mold.MovieMold;
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

    override public function publish(out :IDataOutput, lib :XflLibrary, movies :Vector.<MovieMold>,
            packers :Vector.<Packer>, authoredDevice :DeviceType) :void {
        Molds.registerClassAliases();
        const zip :FZip = new FZip();

        function addToZip(name :String, contentWriter :Function) :void {
            const bytes :ByteArray = new ByteArray();
            contentWriter(bytes);
            zip.addFile(name, bytes);
        }
        addToZip(StarlingResources.MD5_LOCATION,
            function (b :ByteArray) :void { b.writeUTFBytes(lib.md5); });
        addToZip(StarlingResources.MOVIE_LOCATION,
            function (b :ByteArray) :void { b.writeObject(movies); });
        addToZip(StarlingResources.ATLAS_LOCATION, function (b :ByteArray) :void {
            const atlasMolds :Vector.<AtlasMold> = new Vector.<AtlasMold>();
            for each (var atlas :Atlas in packers[0].atlases) atlasMolds.push(atlas.toMold());
            b.writeObject(atlasMolds);
        });
        for each (var atlas :Atlas in packers[0].atlases) {
            addToZip(atlas.fileName, function (b :ByteArray) :void { atlas.writePNG(b); });
        }

        zip.serialize(out, /*includeAdler32=*/true);
    }
}
}
