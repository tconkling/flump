//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;

import flump.mold.require;
import flump.xfl.XflLibrary;

public class ExportConf
{
    public var name :String = "main";
    public var scale :Number = 1;
    public var format :String = "Starling";

    public function create (exportDir :File, lib :XflLibrary) :Format {
        var formatClass :Class;
        switch (format.toLowerCase()) {
            case "json": formatClass = JSONFormat; break;
            case "starling": formatClass = StarlingFormat; break;
            case "xml": formatClass = XMLFormat; break;
            default: throw new Error("Unknown format '" + format + "'");
        }
        return new formatClass(exportDir, lib, this);
    }

    public static function fromJSON (o :Object) :ExportConf {
        const conf :ExportConf = new ExportConf();
        conf.name = require(o, "name");
        conf.scale = require(o, "scale");
        conf.format = require(o, "format");
        return conf;
    }
}
}
