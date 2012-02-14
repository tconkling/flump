//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flash.geom.Matrix;
import flash.geom.Point;

import flump.ParseError;
import flump.ParseErrorSeverity;

import com.threerings.util.XmlUtil;

public class XflKeyframe extends XflComponent
{
    use namespace xflns;

    public var index :int;

    /** The length of this keyframe in frames. */
    public var duration :Number;

    /** The name of the symbol in this keyframe, or null if there is no symbol. */
    public var libraryName :String;

    /** The transform of the symbol in this keyframe, or null if libraryName is null. */
    public var matrix :Matrix;

    /** The tranformation point of the symbol in this keyframe, or null if libraryName is null. */
    public var transformationPoint :Point;

    /** The label on this keyframe, or null if there isn't one */
    public var label :String;

    public function XflKeyframe (baseLocation :String, xml :XML, errors :Vector.<ParseError>) {
        index = XmlUtil.getIntAttr(xml, "index");
        super(baseLocation + ":" + index, errors);
        duration = XmlUtil.getNumberAttr(xml, "duration", 1);
        label = XmlUtil.getStringAttr(xml, "name", null);

        var symbolXml :XML;
        for each (var frameEl :XML in xml.elements.elements()) {
            if (frameEl.name().localName == "DOMSymbolInstance") {
                if (symbolXml != null)  {
                    addError(ParseErrorSeverity.CRIT, "There can be only one symbol instance at " +
                        "a time in a keyframe.");
                } else symbolXml = frameEl;
            } else {
                addError(ParseErrorSeverity.CRIT, "Non-symbols may not be in exported movie " +
                    "layers");
            }
        }

        if (symbolXml == null) return; // Purely labelled frame

        libraryName = XmlUtil.getStringAttr(symbolXml, "libraryItemName");


        const matrixXml :XML = symbolXml.matrix.Matrix[0];
        function m (name :String, def :Number) :Number {
            return matrixXml ? XmlUtil.getNumberAttr(matrixXml, name, def) : def;
        }
        matrix = new Matrix(m("a", 1), m("b", 0), m("c", 0), m("d", 1), m("tx", 0), m("ty", 0));

        const tPoint :XML = symbolXml.transformationPoint.Point[0];
        transformationPoint =
            new Point(XmlUtil.getNumberAttr(tPoint, "x", 0), XmlUtil.getNumberAttr(tPoint, "y", 0));
    }
}
}
