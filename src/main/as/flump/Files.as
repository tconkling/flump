//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.FileListEvent;
import flash.events.IOErrorEvent;
import flash.filesystem.File;

import executor.Executor;
import executor.Future;

import com.threerings.util.F;

public class Files
{
    public static function load (file :File, exec :Executor=null) :Future {
        if (!exec) exec = new Executor();
        return exec.submit(function (onSuccess :Function, onError :Function) :void {
            file.addEventListener(Event.COMPLETE, F.callback(onSuccess, file));
            file.addEventListener(IOErrorEvent.IO_ERROR, onError);
            file.load();
        });
    }

    public static function list (dir :File, exec :Executor) :Future {
        return exec.submit(function (onSuccess :Function, onError :Function) :void {
            dir.addEventListener(FileListEvent.DIRECTORY_LISTING,
                function (ev :FileListEvent) :void { onSuccess(ev.files) });
            dir.addEventListener(ErrorEvent.ERROR, onError);
            dir.getDirectoryListingAsync();
        });
    }
}
}
