//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.utils.IDataOutput;

import flump.mold.AtlasMold;

import starling.textures.Texture;

public interface Atlas
{
    function get area () :int;
    function get filename () :String;
    function get used () :int;

    function writePNG (bytes :IDataOutput) :void;
    function toTexture () :Texture;
    function toMold () :AtlasMold;
}
}