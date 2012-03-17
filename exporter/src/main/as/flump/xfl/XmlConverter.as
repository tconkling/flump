//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {


public class XmlConverter
{
    public var xml :XML;

    public function XmlConverter (xml :XML) {
        this.xml = xml;
    }

    public function hasAttr (name :String) :Boolean {
        return (xml.attribute(name)[0] != null);
    }

    public function getStringAttr (name :String, defaultValue :* = undefined) :String {
        return getAttr(name, defaultValue);
    }

    public function getAttr (name :String, defaultValue :*, parseFunction :Function = null) :* {
        var value :*;

        // read the attribute; throw an error if it doesn't exist (unless we have a default value)
        var attr :XML = xml.attribute(name)[0];
        if (null == attr) {
            if (undefined !== defaultValue) {
                return defaultValue;
            } else {
                throw new Error(
                        "error reading attribute '" + name + "': attribute does not exist");
            }
        }

        // try to parse the attribute
        try {
            value = (null != parseFunction ? parseFunction(attr) : attr);
        } catch (e :ArgumentError) {
            throw new Error("error reading attribute '" + name + "': " + e.message);
        }

        return value;
    }

    public function getIntAttr (name :String, defaultValue :* = undefined) :int {
        return getAttr(name, defaultValue, parseInt);
    }

    public function getNumberAttr (name :String, defaultValue :* = undefined) :Number {
        return getAttr(name, defaultValue, parseFloat);
    }

    public function getBooleanAttr (name :String, defaultValue :* = undefined) :Boolean {
        return getAttr(name, defaultValue, function (v :String) :Boolean { return v == "true" });
    }
}
}
