//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import com.threerings.util.Enum;

public final class DeviceType extends Enum
{
    public static const IPHONE :DeviceType = new DeviceType("IPHONE", "", 0.5);
    public static const IPHONE_RETINA :DeviceType = new DeviceType("IPHONE_RETINA", "@2x", 1);
    finishedEnumerating(DeviceType);

    public function get scale () :Number {
        return _scale;
    }

    public function get extension () :String {
        return _extension;
    }

    public function DeviceType (name:String, extension :String, scale :Number) {
        super(name);
        _extension = extension;
        _scale = scale;
    }

    public static function valueOf (name :String) :DeviceType {
        return Enum.valueOf(DeviceType, name) as DeviceType;
    }

    public static function values () :Array {
        return Enum.values(DeviceType);
    }

    protected var _extension :String;
    protected var _scale :Number;
}
}
