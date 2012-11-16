//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;

import flump.xfl.XflLibrary;

public class Format
{
    public function Format (destDir :File, lib :XflLibrary, conf :ExportConf) {
        _lib = lib;
        _destDir = destDir;
        _conf = conf;
    }

    public function get modified () :Boolean { throw new Error("Must be implemented by a subclass"); }

    public function publish() :void { throw new Error("Must be implemented by a subclass"); }

    protected var _lib :XflLibrary;
    protected var _destDir :File;
    protected var _conf :ExportConf;

}
}
