//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import com.threerings.util.Enum;

public class Ternary extends Enum
{
    public static const TRUE :Ternary = new Ternary("TRUE");
    public static const FALSE :Ternary = new Ternary("FALSE");
    public static const UNKNOWN :Ternary = new Ternary("UNKNOWN");
    finishedEnumerating(Ternary);

    public function Ternary (name :String) {
        super(name);
    }

    public static function valueOf (name :String) :Ternary {
        return Enum.valueOf(Ternary, name) as Ternary;
    }

   public static function values () :Array { return Enum.values(Ternary); }

   public static function of (value :Boolean) :Ternary { return value ? TRUE : FALSE; }
}
}
