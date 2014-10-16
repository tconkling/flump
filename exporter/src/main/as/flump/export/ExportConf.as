//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import aspire.util.Log;
import aspire.util.Set;
import aspire.util.Sets;
import aspire.util.StringUtil;

import flash.display.StageQuality;
import flash.filesystem.File;

import flump.mold.AtlasMold;
import flump.mold.optional;
import flump.mold.require;
import flump.xfl.XflLibrary;

public class ExportConf
{
    public static const OPTIMIZE_MEMORY :String = "Memory";
    public static const OPTIMIZE_SPEED :String = "Speed";

    public var name :String = "default";
    public var format :String = JSONZipFormat.NAME;
    public var scale :Number = 1;
    /** The size of the border around each texture in an atlas, in pixels */
    public var textureBorder :int = 1;
    /** The maximum size of the width and height of a generated texture atlas */
    public var maxAtlasSize :int = 2048;
    /** Scale factors to output */
    public var scaleFactors :Array = [ 1 ];
    /** The optimization strategy. */
    public var optimize :String = OPTIMIZE_SPEED;
    /** The stage quality setting (StageQuality). */
    public var quality :String = StageQuality.BEST;
    /** Whether or not to pretty print the library. */
    public var prettyPrint :Boolean = false;
    /** Whether or not to combine all FLAs into a single library */
    public var combine :Boolean = false;

    public function get scaleFactorsString () :String {
        return this.scaleFactors.join(",");
    }

    public function set scaleFactorsString (str :String) :void {
        var values :Set = Sets.newSetOf(int);
        for each (var num :String in str.split(",")) {
            try {
                // scale factors must be integers >= 1
                var scale :int = StringUtil.parseUnsignedInteger(StringUtil.trim(num));
                if (scale >= 1) {
                    values.add(scale);
                }
            } catch (e :Error) {}
        }

        this.scaleFactors = values.toArray();
        this.scaleFactors.sort();
    }

    public function get description () :String {
        const scaleString :String = (this.scale * 100).toFixed(0) + "%";
        var scaleFactors :String = "";
        for each (var scaleFactor :int in this.scaleFactors) {
            scaleFactors += ", ";
            if (scaleFactor == 1) scaleFactors += "@1x";
            else scaleFactors += AtlasMold.scaleFactorSuffix(scaleFactor);
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
        conf.scaleFactors = require(o, "scaleFactors");
        conf.optimize = optional(o, "optimize", OPTIMIZE_MEMORY);
        conf.quality = optional(o, "quality", StageQuality.BEST);
        conf.prettyPrint = optional(o, "prettyPrint", false);
        conf.combine = optional(o, "combine", false);
        return conf;
    }

    public function createPublishFormat (exportDir :File,
            libs :Vector.<XflLibrary>, projectName :String) :PublishFormat {
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
        return new formatClass(exportDir, libs, this, projectName);
    }

    protected static const log :Log = Log.getLog(ExportConf);
}
}
