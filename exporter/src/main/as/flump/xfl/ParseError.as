//
// Flump - Copyright 2013 Flump Authors

package flump.xfl {

public class ParseError
{
    public static const DEBUG :String = "Debug";
    public static const INFO :String = "Info";
    public static const WARN :String = "Warning";
    public static const CRIT :String = "Critical";

    public static function severityToOrdinal(sev :String) :int {
        if (sev === DEBUG) return 0;
        else if (sev === INFO) return 1;
        else if (sev=== WARN) return 2;
        else return 3;
    }

    public function ParseError (location :String=null, severity :String=null, message :String=null,
        error :Object=null) {
        _severity = severity;
        _message = message;
        _location = location;
        _error = error;
    }

    public function get severity () :String { return _severity; }
    public function get sevOrdinal() :int { return severityToOrdinal(_severity); }

    public function get message () :String { return _message; }
    public function get location () :String { return _location; }

    /** The error that caused this parse error, or null if it wasn't caused by an error.  */
    public function get error () :Object { return _error; }

    public function toString () :String {
        return "ParseError [location=" + _location + ", severity=" + _severity + ", message=" +
          _message + ", error=" + _error + "]";
    }

    protected var _severity :String;
    protected var _message :String;
    protected var _location :String;
    protected var _error :Object;
}
}
