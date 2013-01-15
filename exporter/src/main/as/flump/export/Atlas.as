//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flash.display.BitmapData;

import flump.mold.AtlasMold;

public interface Atlas
{
    function get area () :int;
    function get filename () :String;
    function get used () :int;

    function get scaleFactor () :int;

    function toBitmap () :BitmapData;
    function toMold () :AtlasMold;
}
}
