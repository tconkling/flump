//
// Flump - Copyright 2012 Three Rings Design

package flump.mold {

import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.registerClassAlias;
import flash.utils.getQualifiedClassName;

public class Molds
{
    public static function registerClassAliases () :void {
        for each (var klass :Class in _amfClasses) {
            registerClassAlias(getQualifiedClassName(klass), klass);
        }
        _amfClasses = [];// Only do this once
    }

    protected static var _amfClasses :Array = [
        AtlasMold,
        AtlasTextureMold,
        KeyframeMold,
        LayerMold,
        LibraryMold,
        MovieMold,

        Point,
        Rectangle
    ];

}
}
