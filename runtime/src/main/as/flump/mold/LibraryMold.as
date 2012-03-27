//
// Flump - Copyright 2012 Three Rings Design

package flump.mold {

import flash.net.registerClassAlias;

public class LibraryMold
{
    // Make this come out as itself in AMF
    registerClassAlias("LibraryMold", LibraryMold);

    // The frame rate of movies in this library
    public var frameRate :Number;

    // The MD5 of the published library SWF
    public var md5 :String;

    public var movies :Vector.<MovieMold> = new Vector.<MovieMold>();

    public var atlases :Vector.<AtlasMold> = new Vector.<AtlasMold>();
}
}
