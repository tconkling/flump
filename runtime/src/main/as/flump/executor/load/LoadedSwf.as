//
// Flump - Copyright 2013 Flump Authors

package flump.executor.load {

import flash.display.DisplayObject;
import flash.display.Loader;
import flash.system.ApplicationDomain;

public class LoadedSwf
{
    public function LoadedSwf (loader :Loader) {
        _loader = loader;
    }

    public function getSymbol (name :String) :Object {
        try {
            return _loader.contentLoaderInfo.applicationDomain.getDefinition(name);
        } catch (e :Error) {} // swallow the exception and return null
        return null;
    }

    public function hasSymbol (name :String) :Boolean {
        return _loader.contentLoaderInfo.applicationDomain.hasDefinition(name);
    }

    public function get applicationDomain () :ApplicationDomain {
        return _loader.contentLoaderInfo.applicationDomain;
    }

    public function get displayRoot () :DisplayObject {
        return _loader.content;
    }

    public function unload () :void {
        try {
            _loader.unload();
        } catch (e :Error) {} // swallow exceptions
    }

    protected var _loader :Loader;
}
}
