//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;
import flash.utils.ByteArray;
import flash.utils.IDataOutput;

import flump.mold.MovieMold;
import flump.xfl.XflLibrary;

public class Format
{
    public var metaFilename :String;

    public function Format (metaFilename :String) {
        this.metaFilename = metaFilename;
    }

    public function getMetadata (destDir :File) :File {
        return destDir.resolvePath(metaFilename);

    }

    public function publish(out :IDataOutput, lib :XflLibrary, movies :Vector.<MovieMold>,
        packers :Vector.<Packer>, authoredDevice :DeviceType) :void {
        throw new Error("Must be implemented by a subclass");
    }

    public function extractMd5 (metadata :ByteArray) :String {
        throw new Error("Must be implemented by a subclass");
    }

}
}
