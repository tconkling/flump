//
// aciv

package flump.xfl {

public class XflSymbol
{
    use namespace xflns;

    public static const NAME :String = "name";

    public static const TYPE :String = "symbolType";
    public static const TYPE_GRAPHIC :String = "graphic";
    public static const IS_SPRITE :String = "isSpriteSubclass";

    public static const EXPORT_FOR_ACTIONSCRIPT :String = "linkageExportForAS";
    public static const EXPORT_IN_FIRST_FRAME :String = "linkageExportInFirstFrame";
    public static const EXPORT_CLASS_NAME :String = "linkageClassName";

    public static const SYMBOL_ITEM :String = "DOMSymbolItem";

    public static function isSymbolItem (xml :XML) :Boolean {
        return (xml.name().localName == SYMBOL_ITEM);
    }
}
}
