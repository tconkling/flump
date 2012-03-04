//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flash.geom.Matrix;

import flump.MatrixUtil;

public class XflKeyframe extends XflComponent
{
    use namespace xflns;

    public var index :int;

    /** The length of this keyframe in frames. */
    public var duration :Number;

    /** The name of the libraryItem in this keyframe, or null if there is no libraryItem. */
    public var libraryItem :String;

    /** The name of the symbol in this keyframe, or null if there is no symbol. */
    public var symbol :String;

    /** The transform of the symbol in this keyframe, or null if libraryName is null. */
    public var matrix :Matrix;

    /** The label on this keyframe, or null if there isn't one */
    public var label :String;

    /** Exploded values from matrix */
    public var x :Number = 0.0, y :Number = 0.0, scaleX :Number = 1.0, scaleY :Number = 1.0,
        rotation :Number = 0.0;

    public function XflKeyframe (baseLocation :String, xml :XML, errors :Vector.<ParseError>,
        flipbook :Boolean) {
        const converter :XmlConverter = new XmlConverter(xml);
        index = converter.getIntAttr("index");
        super(baseLocation + ":" + index, errors);
        duration = converter.getNumberAttr("duration", 1);
        label = converter.getStringAttr("name", null);

        if (flipbook) return;
        var symbolXml :XML;
        for each (var frameEl :XML in xml.elements.elements()) {
            if (frameEl.name().localName == "DOMSymbolInstance") {
                if (symbolXml != null)  {
                    addError(ParseError.CRIT, "There can be only one symbol instance at " +
                        "a time in a keyframe.");
                } else symbolXml = frameEl;
            } else {
                addError(ParseError.CRIT, "Non-symbols may not be in exported movie " +
                    "layers");
            }
        }

        if (symbolXml == null) return; // Purely labelled frame

        if (!isClassicTween(xml)) {
            addError(ParseError.WARN, "Motion and Shape tweens are not supported");
        }

        libraryItem = new XmlConverter(symbolXml).getStringAttr("libraryItemName");


        const matrixXml :XML = symbolXml.matrix.Matrix[0];
        const matrixConverter :XmlConverter =
            matrixXml == null ? null : new XmlConverter(matrixXml);
        function m (name :String, def :Number) :Number {
            return matrixConverter == null ? def : matrixConverter.getNumberAttr(name, def);
        }
        matrix = new Matrix(m("a", 1), m("b", 0), m("c", 0), m("d", 1), m("tx", 0), m("ty", 0));

        x = matrix.tx;
        y = matrix.ty;
        rotation = MatrixUtil.rotation(matrix);
        scaleX = MatrixUtil.scaleX(matrix);
        scaleY = MatrixUtil.scaleY(matrix);
    }

    public function checkSymbols (lib :XflLibrary) :void {
        if (symbol != null && !lib.hasSymbol(symbol)) {
            addError(ParseError.CRIT, "Symbol '" + symbol + "' not exported");
        }
    }

    public function toJSON (_:*) :Object {
        var json :Object = {
            index: index,
            duration: duration
        };
        if (libraryItem != null) {
            json.ref = symbol;
            json.t = [ x, y, scaleX, scaleY, rotation ];
            // json.alpha = 1;
        }
        if (label != null) {
            json.label = label;
        }
        return json;
    }

    protected static function isClassicTween (xml :XML) :Boolean {
        const converter :XmlConverter = new XmlConverter(xml);
        if (converter.hasAttr("motionTweenRotate") ||
            converter.hasAttr("motionTweenRotateTimes")) {
            return false;
        }

        return true;
    }
}
}
