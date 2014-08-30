//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import aspire.util.Log;

import flash.filesystem.File;

import flump.xfl.XflLibrary;

public class Publisher
{
    public function Publisher (exportDir :File, project :ProjectConf) {
        _exportDir = exportDir;
        for each (var export :ExportConf in project.exports) _confs.push(export);
    }

    public function modified (libs :Vector.<XflLibrary>, idx :int = -1) :Boolean {
        // Instantiate all formats and check for modified. For a ProjectConf that contains combined
        // exports, all individual libs will check as modified if any single lib is modified
        return instantiate(libs, idx).some(function (export :PublishFormat, ..._) :Boolean {
            return export.modified;
        });
    }

    public function publishSingle (lib :XflLibrary) :void {
        var libs :Vector.<XflLibrary> = new <XflLibrary>[lib];
        for each (var format :PublishFormat in instantiate(libs, 0, false)) format.publish();
    }

    public function publishCombined (libs :Vector.<XflLibrary>) :void {
        // no index passed to instantiate() acts as a <do not include non-combined> flag
        for each (var format :PublishFormat in instantiate(libs)) format.publish();
    }

    protected function instantiate (libs :Vector.<XflLibrary>,
            idx :int = -1, includeCombined :Boolean = true) :Vector.<PublishFormat> {
        const formats :Vector.<PublishFormat> = new <PublishFormat>[];
        for each (var conf :ExportConf in _confs) {
            if (conf.combine && includeCombined) {
                formats.push(conf.createPublishFormat(_exportDir, libs));
            } else if (!conf.combine && idx >= 0) {
                formats.push(conf.createPublishFormat(_exportDir, new <XflLibrary>[libs[idx]]))
            }
        }
        return formats;
    }

    private var _exportDir :File;
    private const _confs :Vector.<ExportConf> = new <ExportConf>[];
    private static const log :Log = Log.getLog(Publisher);
}
}
