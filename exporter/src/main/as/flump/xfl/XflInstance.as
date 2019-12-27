//
// aciv

package flump.xfl {

public class XflInstance
{
    use namespace xflns;

    public static const LIBRARY_ITEM_NAME :String = "libraryItemName";
    public static const IS_VISIBLE :String = "isVisible";
    public static const ALPHA :String = "alphaMultiplier";
    public static const TINT_MULTIPLIER :String = "tintMultiplier";
    public static const TINT :String = "tintColor";

    public static function getColorXml (instanceXml :XML) :XML {
        return (instanceXml.color != null ? instanceXml.color.Color[0] : null);
    }

    public static function getTransformationPointXml (instanceXml :XML) :XML {
        return (instanceXml.transformationPoint != null ?
            instanceXml.transformationPoint.Point[0] : null);
    }

    public static function getMatrixXml (instanceXml :XML) :XML {
        return (instanceXml.matrix != null ? instanceXml.matrix.Matrix[0] : null);
    }
}
}
