//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import executor.load.LoadedSwf;

import com.threerings.util.Set;
import com.threerings.util.Sets;

public class XflLibrary extends XflTopLevelComponent
{
    public var swf :LoadedSwf;
    public const movies :Vector.<XflMovie> = new Vector.<XflMovie>();
    public const textures :Vector.<XflTexture> = new Vector.<XflTexture>();

    public function XflLibrary(location :String) {
        super(location);
    }

    public function finishLoading () :void {
        const symbols :Set = Sets.newSetOf(String);
        for each (var tex :XflTexture in textures) symbols.add(tex.name);
        for each (var movie :XflMovie in movies) symbols.add(movie.name);
        for each (movie in movies) movie.checkSymbols(symbols);
    }

    override public function getErrors (sev :ParseErrorSeverity=null) :Vector.<ParseError>{
        var base :Vector.<ParseError> = super.getErrors(sev).concat();
        for each (var movie :XflMovie in movies) base = base.concat(movie.getErrors(sev));
        for each (var tex :XflTexture in textures) base = base.concat(tex.getErrors(sev));
        return base;
    }
}
}
