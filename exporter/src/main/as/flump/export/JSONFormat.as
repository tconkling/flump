//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.utils.ByteArray;
import flash.utils.IDataOutput;

import flump.mold.MovieMold;
import flump.xfl.XflLibrary;

public class JSONFormat extends Format
{
    public function JSONFormat () {
        super("resources.json");
    }

    override public function extractMd5 (metadata :ByteArray) :String {
        return JSON.parse(metadata.readUTFBytes(metadata.length)).md5;
    }

    override public function publish(out :IDataOutput, lib :XflLibrary, movies :Vector.<MovieMold>,
        packers :Vector.<Packer>, authoredDevice :DeviceType) :void {
        var json :Object = {
            md5: lib.md5,
            movies: movies,
            atlases: packers[0].atlases
        };
        var pretty :Boolean = false;
        out.writeUTFBytes(JSON.stringify(json, null, pretty ? "  " : null));
    }
}
}
