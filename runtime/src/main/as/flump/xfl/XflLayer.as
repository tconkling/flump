//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

public class XflLayer extends XflComponent
{
    use namespace xflns;

    public var name :String;
    public const keyframes :Vector.<XflKeyframe> = new Vector.<XflKeyframe>();
    public var flipbook :Boolean;

    public function XflLayer (baseLocation :String, xml :XML, errors :Vector.<ParseError>,
        flipbook :Boolean) {
        name = new XmlConverter(xml).getStringAttr("name");
        this.flipbook = flipbook;
        super(baseLocation + ":" + name, errors);
        for each (var frameEl :XML in xml.frames.DOMFrame) {
            keyframes.push(new XflKeyframe(location, frameEl, _errors, flipbook));
        }
        if (keyframes.length == 0) addError(ParseError.INFO, "No keyframes on layer");
    }

    public function keyframeForFrame (frame :int) :XflKeyframe {
        var ii :int = 1;
        for (; ii < keyframes.length && keyframes[ii].index <= frame; ii++) {}
        return keyframes[ii - 1];
    }

    public function get frames () :int {
        const lastKf :XflKeyframe = keyframes[keyframes.length - 1];
        return lastKf.index + lastKf.duration;
    }

    public function checkSymbols (lib :XflLibrary) :void {
        for each (var kf :XflKeyframe in keyframes) kf.checkSymbols(lib);
    }

    public function toJSON (_:*) :Object {
        var json :Object = {
            name: name,
            keyframes: keyframes
        };
        if (flipbook) {
            json.flipbook = flipbook;
        }
        return json;
    }

    public function toXML () :XML
    {
        var xml :XML = <layer name={name}/>
        if (flipbook) {
            xml.@flipbook = flipbook;
        }

        for each (var kf :XflKeyframe in keyframes) {
            xml.appendChild(kf.toXML());
        }
        return xml;
    }
}
}
