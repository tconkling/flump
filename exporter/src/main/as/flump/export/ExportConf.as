//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flash.filesystem.File;

import flump.mold.AtlasMold;
import flump.mold.optional;
import flump.mold.require;
import flump.xfl.XflLibrary;

import com.threerings.util.Log;
import com.threerings.util.Set;
import com.threerings.util.Sets;
import com.threerings.util.StringUtil;

public class ExportConf
{
    public var name :String = "default";
    public var format :String = JSONZipFormat.NAME;
    public var scale :Number = 1;
    /** The size of the border around each texture in an atlas, in pixels */
    public var textureBorder :int = 1;
    /** The maximum size of the width and height of a generated texture atlas */
    public var maxAtlasSize :int = 2048;
    /** Additional scaleFactors to output */
    public var additionalScaleFactors :Array = [];

    public function get scaleFactorsString () :String {
        return this.additionalScaleFactors.join(",");
    }

    public function set scaleFactorsString (str :String) :void {
        var strings :Array = str.split(",");
        var values :Set = Sets.newSetOf(int);
        for each (var num :String in str.split(",")) {
            try {
                // additional scale factors must be integers > 1
                var scale :int = StringUtil.parseUnsignedInteger(StringUtil.trim(num));
                if (scale > 1) {
                    values.add(scale);
                }
            } catch (e :Error) {}
        }

        this.additionalScaleFactors = values.toArray();
        this.additionalScaleFactors.sort();
    }

    public function get description () :String {
        const scaleString :String = (this.scale * 100).toFixed(0) + "%";
        var scaleFactors :String = "";
        for each (var scaleFactor :int in this.additionalScaleFactors) {
            scaleFactors += ", " + AtlasMold.scaleFactorSuffix(scaleFactor);
        }

        return "'" + this.name + "' (" + this.format + ", " + scaleString + scaleFactors + ")";
    }

    public static function fromJSON (o :Object) :ExportConf {
        const conf :ExportConf = new ExportConf();
        conf.name = require(o, "name");
        conf.scale = require(o, "scale");
        conf.format = require(o, "format");
        conf.textureBorder = optional(o, "textureBorder", 1);
        conf.maxAtlasSize = optional(o, "maxAtlasSize", 2048);
        conf.additionalScaleFactors = optional(o, "additionalScaleFactors", []);
        return conf;
    }

    public function createPublishFormat (exportDir :File, lib :XflLibrary) :PublishFormat {
        var formatClass :Class;
        switch (format.toLowerCase()) {
            case JSONFormat.NAME.toLowerCase(): formatClass = JSONFormat; break;
            case JSONZipFormat.NAME.toLowerCase(): formatClass = JSONZipFormat; break;
            case XMLFormat.NAME.toLowerCase(): formatClass = XMLFormat; break;
            default:
                log.error("Invalid publish format", "name", format);
                formatClass = JSONZipFormat;
                break;
        }
        return new formatClass(exportDir, lib, this);
    }

    protected static const log :Log = Log.getLog(ExportConf);
}
}
