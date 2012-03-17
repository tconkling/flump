//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.net.ObjectEncoding;
import flash.net.registerClassAlias;
import flash.utils.ByteArray;

import flump.xfl.XflKeyframe;
import flump.xfl.XflLayer;
import flump.xfl.XflLibrary;
import flump.xfl.XflMovie;

public class StarlingPublisher
{
    public static function publish (lib :XflLibrary, source: File, authoredDevice :DeviceType,
            exportDir :File) :void {
       trace("Publishing " + lib);
       var out :FileStream = new FileStream();
       out.open(exportDir.resolvePath("lib.amf"), FileMode.WRITE);
       registerClassAlias("flump.xfl.XflLibrary", XflLibrary);
       registerClassAlias("flump.xfl.XflKeyframe", XflKeyframe);
       registerClassAlias("flump.xfl.XflLayer", XflLayer);
       registerClassAlias("flump.xfl.XflMovie", XflMovie);
       const amf :ByteArray = new ByteArray();
       amf.objectEncoding = ObjectEncoding.AMF3;
       amf.writeObject(lib);
       out.writeBytes(amf);
       out.close();
    }

}
}
