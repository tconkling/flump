//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flump.ParseError;
import flump.ParseErrorSeverity;

public class XflComponent
{
    public var location :String;

    public function XflComponent(location :String, errors :Vector.<ParseError>) {
        this.location = location;
        _errors = errors;
    }

    public function getErrors (sev :ParseErrorSeverity=null) :Vector.<ParseError> {
        if (sev == null) return _errors;
        return _errors.filter(function (err :ParseError, ..._) :Boolean {
            return err.severity.ordinal() >= sev.ordinal();
        });
    }

    public function get valid () :Boolean {
        return getErrors(ParseErrorSeverity.CRIT).length == 0;
    }

    public function addError(severity :ParseErrorSeverity, message :String, e :Object=null) :void {
        _errors.push(new ParseError(location, severity, message, e));
    }

    protected var _errors :Vector.<ParseError>;

}
}
