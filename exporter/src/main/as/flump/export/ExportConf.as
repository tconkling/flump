//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;

import flump.mold.require;
import flump.xfl.XflLibrary;

public class ExportConf
{
    public var name :String;
    public var scale :Number = 1;
    public var format :Class = StarlingFormat;

    public function create (exportDir :File, lib :XflLibrary) :Format {
        return new format(exportDir, lib, this);
    }

    public static function fromJSON (o :Object) :ExportConf {
        const conf :ExportConf = new ExportConf();
        conf.name = require(o, "name");
        conf.scale = require(o, "scale");
        const formatName :String = require(o, "format");
        if (formatName == "Starling") conf.format = StarlingFormat;
        else if (formatName == "XML") conf.format = XMLFormat;
        else if (formatName == "JSON") conf.format = JSONFormat;
        else throw new Error("Unknown format '" + formatName + "'");
        return conf;
    }

    public function toJSON (_ :*) :Object {
        var formatName :String;
        if (format == StarlingFormat) formatName = "Starling";
        else if (format == XMLFormat) formatName = "XML";
        else if (format == JSONFormat) formatName = "JSON";
        else throw new Error("Unknown format '" + format + "'");
        return {
            name: name,
            scale: scale,
            format: formatName
        };
    }
}
}
