//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import com.threerings.util.sprintf;

public class ParseError
{
    public function ParseError (location :String, severity :ParseErrorSeverity, message :String,
        error :Object=null) {
        _severity = severity;
        _message = message;
        _location = location;
        _error = error;
    }

    public function get severity () :ParseErrorSeverity { return _severity; }
    public function get message () :String { return _message; }
    public function get location () :String { return _location; }

    /** The error that caused this parse error, or null if it wasn't caused by an error.  */
    public function get error () :Object { return _error; }

    public function toString () :String {
        return sprintf("ParseError [location=%s, severity=%s, message=%s, error=%s]",
            _location, _severity, _message, _error);
    }

    protected var _severity :ParseErrorSeverity;
    protected var _message :String;
    protected var _location :String;
    protected var _error :Object;
}
}
