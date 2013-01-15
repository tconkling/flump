//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flash.net.SharedObject;

public class FlumpSettings
{
    public static function get projectWindowSettings () :Array {
        load();
        var settings :Array = _settings.data[PROJECT_WINDOW_SETTINGS];
        if (settings == null) {
            return [];
        } else {
            return settings.map(function (obj :Object, ..._) :ProjectWindowSettings {
                return ProjectWindowSettings.fromObject(obj);
            });
        }

        return (settings != null ? settings : []);
    }

    public static function set projectWindowSettings (settings :Array) :void {
        load();
        _settings.data[PROJECT_WINDOW_SETTINGS] = settings;
        _settings.flush();
    }

    protected static function load () :void {
        if (_settings == null) {
            _settings = SharedObject.getLocal("flump/exporter");
        }
    }

    protected static var _settings :SharedObject;

    protected static const PROJECT_WINDOW_SETTINGS :String = "PROJECT_WINDOW_SETTINGS";
}
}
