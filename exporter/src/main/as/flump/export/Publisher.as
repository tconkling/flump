//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flash.filesystem.File;

import flump.xfl.XflLibrary;

import com.threerings.util.Log;

public class Publisher
{
    public function Publisher (exportDir :File, project :ProjectConf) {
        _exportDir = exportDir;
        for each (var export :ExportConf in project.exports) _confs.push(export);
    }

    public function modified (lib :XflLibrary) :Boolean {
        return instantiate(lib).some(function (export :PublishFormat, ..._) :Boolean {
            return export.modified;
        });
    }

    public function publish (lib :XflLibrary) :void {
        for each (var format :PublishFormat in instantiate(lib)) format.publish();
    }

    protected function instantiate (lib :XflLibrary) :Vector.<PublishFormat> {
        const formats :Vector.<PublishFormat> = new <PublishFormat>[];
        for each (var conf :ExportConf in _confs) formats.push(conf.createPublishFormat(_exportDir, lib));
        return formats;
    }

    private var _exportDir :File;
    private const _confs :Vector.<ExportConf> = new <ExportConf>[];
    private static const log :Log = Log.getLog(Publisher);
}
}
