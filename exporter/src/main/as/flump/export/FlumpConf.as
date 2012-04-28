//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flump.mold.require;

public class FlumpConf
{
    public var exportDir :String;
    public var importDir :String;

    public var exports :Array = [ new ExportConf() ];

    public static function fromJSON (o :Object) :FlumpConf {
        const conf :FlumpConf = new FlumpConf();
        conf.exportDir = require(o, "exportDir");
        conf.importDir = require(o, "importDir");
        conf.exports = [];
        for each (var ex :Object in require(o, "exports")) conf.exports.push(ExportConf.fromJSON(ex));
        return conf;
    }

}
}
