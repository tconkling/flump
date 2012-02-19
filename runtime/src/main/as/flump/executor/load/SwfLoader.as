//
// Executor - Copyright 2012 Three Rings Design

package flump.executor.load {

import flash.display.Loader;

public class SwfLoader extends BaseLoader
{
    public function useCurrentDomain () :SwfLoader {
        _useSubDomain = false;
        return this;
    }

    override protected function handleSuccess (onSuccess :Function, loader :Loader) :void {
        onSuccess(new LoadedSwf(loader));
    }
}
}
