//
// Flump - Copyright 2013 Flump Authors

package flump.executor.load {

import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.ImageDecodingPolicy;
import flash.system.LoaderContext;
import flash.utils.ByteArray;

import flump.executor.Executor;
import flump.executor.Future;

public class BaseLoader
{
   public function loadFromBytes (bytes :ByteArray, exec :Executor = null) :Future {
        return submitLoader(exec, function (loader :Loader, context :LoaderContext) :void {
            loader.loadBytes(bytes, context);
        });
    }

    public function loadFromClass (klass :Class, exec :Executor = null) :Future {
        return submitLoader(exec, function (loader :Loader, context :LoaderContext) :void {
            loader.loadBytes(ByteArray(new klass()), context);
        });

    }

    public function loadFromUrl (url :String, exec :Executor = null) :Future {
        return submitLoader(exec, function (loader :Loader, context :LoaderContext) :void {
            loader.load(new URLRequest(url), context);
        });
    }

    protected function handleSuccess (onSuccess :Function, loader :Loader) :void {}

    protected function submitLoader (exec :Executor, loadExecer :Function) :Future {
        if (exec == null) exec = new Executor();
        const context :LoaderContext = new LoaderContext();
        // allowLoadBytesCodeExecution is an AIR-only LoaderContext property that must be true
        // to avoid 'SecurityError: Error #3015' when loading swfs with executable code
        try {
            Object(context)["allowLoadBytesCodeExecution"] = true;
        } catch (e :Error) {}
        if (_useSubDomain) {
            context.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
        } else {
            context.applicationDomain = ApplicationDomain.currentDomain;
        }
        context.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
        return exec.submit(function (onSuccess :Function, onFail :Function) :void {
            const loader :Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.INIT, function (..._) :void {
                handleSuccess(onSuccess, loader);
            });
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onFail);
            loadExecer(loader, context);
        });
    }

    // default to loading symbols into a subdomain
    protected var _useSubDomain :Boolean = true;
}
}
