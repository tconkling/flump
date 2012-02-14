//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flump.ParseError;

public class XflTopLevelComponent extends XflComponent
{
    public function XflTopLevelComponent (location :String) {
        super(location, new Vector.<ParseError>());
    }
}
}
