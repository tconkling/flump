//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import aspire.util.Log;

import flash.filesystem.File;

import flump.xfl.XflLibrary;

public class Publisher
{
    public function Publisher (exportDir :File, project :ProjectConf, projectName :String) {
        _exportDir = exportDir;
        _projectName = projectName;
        for each (var export :ExportConf in project.exports) _confs.push(export);
    }

    public function modified (libs :Vector.<XflLibrary>, idx :int = -1) :Boolean {
        // Instantiate all formats and check for modified. For a ProjectConf that contains combined
        // exports, all individual libs will check as modified if any single lib is modified
        return instantiate(libs, idx).some(function (export :PublishFormat, ..._) :Boolean {
            return export.modified;
        });
    }

    public function publishSingle (lib :XflLibrary) :int {
        var libs :Vector.<XflLibrary> = new <XflLibrary>[lib];
        var formats :Vector.<PublishFormat> = instantiate(libs, 0, false);
        for each (var format :PublishFormat in formats) format.publish();
        return formats.length;
    }

    public function publishCombined (libs :Vector.<XflLibrary>) :int {
        // no index passed to instantiate() acts as a <do not include non-combined> flag
        var formats :Vector.<PublishFormat> = instantiate(libs);
        for each (var format :PublishFormat in formats) format.publish();
        return formats.length;
    }

    protected function instantiate (libs :Vector.<XflLibrary>,
            idx :int = -1, includeCombined :Boolean = true) :Vector.<PublishFormat> {
        const formats :Vector.<PublishFormat> = new <PublishFormat>[];
        for each (var conf :ExportConf in _confs) {
            if (conf.combine && includeCombined) {
                formats.push(conf.createPublishFormat(_exportDir, libs, _projectName));
            } else if (!conf.combine && idx >= 0) {
                formats.push(conf.createPublishFormat(_exportDir, new <XflLibrary>[libs[idx]],
                    _projectName))
            }
        }
        return formats;
    }

    private var _exportDir :File;
    private var _projectName :String;
    private const _confs :Vector.<ExportConf> = new <ExportConf>[];
    private static const log :Log = Log.getLog(Publisher);
}
}
