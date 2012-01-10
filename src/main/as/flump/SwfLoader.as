//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.filesystem.File;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.utils.ByteArray;

import executor.Executor;
import executor.Future;

public class SwfLoader
{
    public function useCurrentDomain () :SwfLoader {
        _useSubDomain = false;
        return this;
    }

    public function loadFromBytes (bytes :ByteArray, exec :Executor = null) :Future {
        return submitLoader(exec, function (loader :Loader, context :LoaderContext) :void {
            loader.loadBytes(bytes, context);
        });
    }

    public function loadFromClass (klass :Class, exec :Executor = null) :Future {
        return submitLoader(exec, function (loader :Loader, context :LoaderContext) :void {
            loader.loadBytes(ByteArray(new klass()), context);
        })

    }

    public function loadFromFile (file :File, exec :Executor = null) :Future {
        if (exec == null) exec = new Executor();
        const context :LoaderContext = createContext();
        return exec.submit(function (onSuccess :Function, onError :Function) :void {
            file.addEventListener(Event.COMPLETE, function (..._) :void {
                load(onSuccess, onError, context,
                    function (loader :Loader, context :LoaderContext) :void {
                        loader.loadBytes(file.data, context);
                });
            });
            file.addEventListener(IOErrorEvent.IO_ERROR, onError);
            file.load();
        });
    }

    public function loadFromUrl (url :String, exec :Executor = null) :Future {
        return submitLoader(exec, function (loader :Loader, context :LoaderContext) :void {
            loader.load(new URLRequest(url), context);
        });
    }

    protected function submitLoader (exec :Executor, loadExecer :Function) :Future {
        if (exec == null) exec = new Executor();
        const context :LoaderContext = createContext();
        return exec.submit(function (onSuccess :Function, onFail :Function) :void {
            load(onSuccess, onFail, context, loadExecer);
        });
    }



    protected function createContext() :LoaderContext {
        const context :LoaderContext = new LoaderContext();
        // allowLoadBytesCodeExecution is an AIR-only LoaderContext property that must be true
        // to avoid 'SecurityError: Error #3015' when loading swfs with executable code
        try {
            Object(context)["allowLoadBytesCodeExecution"] = true;
        } catch (e :Error) {}
        if (_useSubDomain) {
            // default to loading symbols into a subdomain
            context.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
        } else {
            context.applicationDomain = ApplicationDomain.currentDomain;
        }
        return context;
    }

    protected function load (onSuccess :Function, onFail :Function, context :LoaderContext,
        loadExecer :Function) :void {
        const loader :Loader = new Loader();
        loader.contentLoaderInfo.addEventListener(Event.INIT, function (..._) :void {
            onSuccess(new Swf(loader));
        });
        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onFail);
        loadExecer(loader, context);
    }

    protected var _useSubDomain :Boolean = true;
}
}
