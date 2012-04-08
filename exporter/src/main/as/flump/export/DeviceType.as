//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import com.threerings.util.Enum;

public final class DeviceType extends Enum
{
    public static const IPHONE :DeviceType = new DeviceType("IPHONE", "iPhone", "", 480, 320);
    public static const IPHONE_RETINA :DeviceType = new DeviceType("IPHONE_RETINA", "iPhone Retina",
        "@2x", 960, 640);
    public static const IPAD :DeviceType = new DeviceType("IPAD", "iPad", "", 1024, 768);
    public static const IPAD_RETINA :DeviceType = new DeviceType("IPAD_RETINA", "iPad Retina",
        "", 2048, 1536);

    finishedEnumerating(DeviceType);

    public function get displayName () :String { return _displayName; }

    public function get extension () :String { return _extension; }

    public function get resWidth () :int { return _resWidth; }

    public function get resHeight () :int { return _resHeight; }

    public function DeviceType (name :String, displayName :String, extension :String,
        resWidth :int, resHeight :int) {
        super(name);
        _displayName = displayName;
        _extension = extension;
        _resWidth = resWidth;
        _resHeight = resHeight;
    }

    public static function valueOf (name :String) :DeviceType {
        return Enum.valueOf(DeviceType, name) as DeviceType;
    }

    public static function values () :Array { return Enum.values(DeviceType); }

    protected var _displayName :String;
    protected var _extension :String;
    protected var _resWidth :int;
    protected var _resHeight :int;
}
}
