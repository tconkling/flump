//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.utils.IDataOutput;

import flump.mold.AtlasMold;

public interface Atlas
{
    function get area () :int;
    function get filename () :String;
    function get used () :int;

    function writePNG (bytes :IDataOutput) :void;
    function toMold () :AtlasMold;
}
}