//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flump.mold.require;

public class ProjectConf
{
    public var exportDir :String;
    public var importDir :String;

    public var exports :Array = [ new ExportConf() ];

    public static function fromJSON (o :Object) :ProjectConf {
        const conf :ProjectConf = new ProjectConf();
        conf.exportDir = require(o, "exportDir");
        conf.importDir = require(o, "importDir");
        conf.exports = [];
        for each (var ex :Object in require(o, "exports")) conf.exports.push(ExportConf.fromJSON(ex));
        return conf;
    }

}
}
