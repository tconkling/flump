//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.display.BitmapData;

import flump.mold.AtlasMold;

public interface Atlas
{
    function get area () :int;
    function get filename () :String;
    function get used () :int;

    function toBitmap () :BitmapData;
    function toMold () :AtlasMold;
}
}