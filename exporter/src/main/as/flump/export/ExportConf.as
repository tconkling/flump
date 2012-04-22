//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;

import flump.xfl.XflLibrary;

public class ExportConf
{
    public var directory :String;
    public var scale :Number = 1;
    public var format :Class;

    public function create (exportDir :File, lib :XflLibrary) :Format {
        return new format(exportDir, lib, this);
    }
}
}
