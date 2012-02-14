//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import com.threerings.util.Enum;

public class ParseErrorSeverity extends Enum
{
    public static const DEBUG :ParseErrorSeverity = new ParseErrorSeverity("DEBUG", "Debug");
    public static const INFO :ParseErrorSeverity = new ParseErrorSeverity("INFO", "Info");
    public static const WARN :ParseErrorSeverity = new ParseErrorSeverity("WARN", "Warning");
    public static const CRIT :ParseErrorSeverity = new ParseErrorSeverity("CRIT", "Critical");
    finishedEnumerating(ParseErrorSeverity);

    public function ParseErrorSeverity (name :String, display :String) {
        super(name);
        _display = display;
    }

    override public function toString () :String { return _display; }

    protected var _display :String;
}
}
