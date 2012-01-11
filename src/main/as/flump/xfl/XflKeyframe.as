//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flash.geom.Matrix;
import flash.geom.Point;

import com.threerings.util.XmlUtil;

public class XflKeyframe
{
    use namespace xflns;

    public var index :int;
    public var libraryName :String;
    public var matrix :Matrix;
    public var transformationPoint :Point;

    public function XflKeyframe (xml :XML) {
        index = XmlUtil.getIntAttr(xml, "index");

        const symbolXml :XML = xml.elements.DOMSymbolInstance[0];
        libraryName = XmlUtil.getStringAttr(symbolXml, "libraryItemName");

        const matrixXml :XML = symbolXml.matrix.Matrix[0];
        function m (name :String, def :Number) :Number {
            return XmlUtil.getNumberAttr(matrixXml, name, def);
        }
        matrix = new Matrix(m("a", 1), m("b", 0), m("c", 0), m("d", 1), m("tx", 0), m("ty", 0));

        const tPointXML :XML = symbolXml.transformationPoint.Point[0];
        transformationPoint =
            new Point(XmlUtil.getNumberAttr(tPointXML, "x"), XmlUtil.getNumberAttr(tPointXML, "y"));
    }
}
}
