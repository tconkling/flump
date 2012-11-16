//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;

import flump.mold.optional;
import flump.mold.require;
import flump.xfl.XflLibrary;

public class ExportConf
{
    public var name :String = "default";
    public var format :String = "Starling";
    public var scale :Number = 1;
    /** The size of the border around each texture in an atlas, in pixels */
    public var textureBorder :int = 1;

    public function get description () :String {
        return name + " (" + (scale * 100).toFixed(0) + "%, " + textureBorder + "px, " +
            format + ")";
    }

    public function create (exportDir :File, lib :XflLibrary, maxSize :int) :Format {
        var formatClass :Class;
        switch (format.toLowerCase()) {
            case "json": formatClass = JSONFormat; break;
            case "starling": formatClass = StarlingFormat; break;
            case "xml": formatClass = XMLFormat; break;
            default: throw new Error("Unknown format '" + format + "'");
        }
        return new formatClass(exportDir, lib, this, maxSize);
    }

    public static function fromJSON (o :Object) :ExportConf {
        const conf :ExportConf = new ExportConf();
        conf.name = require(o, "name");
        conf.scale = require(o, "scale");
        conf.format = require(o, "format");
        conf.textureBorder = optional(o, "textureBorder", 1);
        return conf;
    }
}
}
