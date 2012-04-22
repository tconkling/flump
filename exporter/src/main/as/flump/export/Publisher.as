//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;

import flump.xfl.XflLibrary;

import com.threerings.util.Log;

public class Publisher
{
    public function Publisher(exportDir :File, export :ExportConf, ...exports) {
        _exportDir = exportDir;
        _confs.push(export);
        for each (export in exports) _confs.push(export);
    }

    public function modified (lib :XflLibrary) :Boolean {
        return instantiate(lib).some(function (export :Format, ..._) :Boolean {
            return export.modified
        });
    }

    public function publish (lib :XflLibrary) :void {
        for each (var format :Format in instantiate(lib)) format.publish();
    }

    protected function instantiate (lib :XflLibrary) :Vector.<Format> {
        const formats :Vector.<Format> = new Vector.<Format>();
        for each (var conf :ExportConf in _confs) formats.push(conf.create(_exportDir, lib));
        return formats;
    }

    private var _exportDir :File;
    private const _confs :Vector.<ExportConf> = new Vector.<ExportConf>();
    private static const log :Log = Log.getLog(Publisher);
}
}
