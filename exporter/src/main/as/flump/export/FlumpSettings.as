//
// flump-exporter

package flump.export {

import flash.net.SharedObject;

public class FlumpSettings
{
    public static function get hasConfigFilePath () :Boolean {
        load();
        return _settings.data.hasOwnProperty(CONF_FILE_KEY);
    }

    public static function get configFilePath () :String {
        load();
        return _settings.data[CONF_FILE_KEY];
    }

    public static function set configFilePath (path :String) :void {
        load();
        _settings.data[CONF_FILE_KEY] = path;
        _settings.flush();
    }

    protected static function load () :void {
        if (_settings == null) {
            _settings = SharedObject.getLocal("flump/exporter");
        }
    }

    protected static var _settings :SharedObject;

    protected static const CONF_FILE_KEY :String = "CONF_FILE";
}
}