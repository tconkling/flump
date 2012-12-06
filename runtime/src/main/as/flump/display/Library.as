//
// Flump - Copyright 2012 Three Rings Design

package flump.display {

import starling.display.DisplayObject;

public interface Library
{
    function get movieSymbols () :Vector.<String>;
    function get imageSymbols () :Vector.<String>;

    function instantiateSymbol (name :String) :DisplayObject;
}

}
