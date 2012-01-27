//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import executor.load.LoadedSwf;

public class XflLibrary
{
    public var swf :LoadedSwf;
    public var name :String;
    public const animations :Vector.<XflAnimation> = new Vector.<XflAnimation>();
    public const textures :Vector.<XflTexture> = new Vector.<XflTexture>();
}
}
