//
// Flump - Copyright 2012 Three Rings Design

package flump.mold {

public class Mold
{
    public var location :String;

    public function Mold(errors :Vector.<ParseError>) {
        _errors = errors;
    }

    public function getErrors (sev :String=null) :Vector.<ParseError> {
        if (sev == null) return _errors;
        const sevOrdinal :int = ParseError.severityToOrdinal(sev);
        return _errors.filter(function (err :ParseError, ..._) :Boolean {
            return err.sevOrdinal >= sevOrdinal;
        });
    }

    public function get valid () :Boolean {
        return getErrors(ParseError.CRIT).length == 0;
    }

    public function addError(severity :String, message :String, e :Object=null) :void {
        _errors.push(new ParseError(location, severity, message, e));
    }

    protected var _errors :Vector.<ParseError>;
}
}
