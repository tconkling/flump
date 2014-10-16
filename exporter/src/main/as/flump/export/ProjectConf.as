//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flump.mold.optional;
import flump.mold.require;
import flump.xfl.ParseError;

public class ProjectConf
{
    public var fileVersion :int;

    public var exportDir :String;
    public var importDir :String;

    public var exports :Array = [ new ExportConf() ];

    public static function fromJSON (o :Object) :ProjectConf {
        var fileVersion :int = optional(o, "fileVersion", 1);
        if (fileVersion > CONF_VERSION) {
            throw new ParseError("configuration", ParseError.CRIT,
                "Project configuration version is too high to read with this version of Flump (" +
                    fileVersion + " vs " + CONF_VERSION + " or lower expected).");
        }
        if (fileVersion < CONF_VERSION) {
            // make sure the prop is set to start, eliminating invalid values
            o["fileVersion"] = Math.max(fileVersion, 1);
            migrate(o, fileVersion + 1);
        }

        const conf :ProjectConf = new ProjectConf();
        conf.fileVersion = require(o, "fileVersion");
        conf.exportDir = require(o, "exportDir");
        conf.importDir = require(o, "importDir");
        conf.exports = [];
        for each (var ex :Object in require(o, "exports")) conf.exports.push(ExportConf.fromJSON(ex));
        return conf;
    }

    protected static function migrate (o :Object, targetVersion :int) :void {
        if (targetVersion == 2) {
            // version 2 changes "additionalScaleFactors" to "scaleFactors", turning the implied
            // factor of 1 into an explicitly listed factor
            for each (var ex :Object in require(o, "exports")) {
                var additional :Array = optional(ex, "additionalScaleFactors", []);
                delete ex["additionalScaleFactors"];
                additional.unshift(1);
                ex["scaleFactors"] = additional;
            }
        }

        o["fileVersion"] = targetVersion;
        if (++targetVersion < CONF_VERSION) migrate(o, targetVersion);
    }

    protected static const CONF_VERSION :int = 2;
}
}
