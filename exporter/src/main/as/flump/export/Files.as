//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.FileListEvent;
import flash.events.IOErrorEvent;
import flash.filesystem.File;

import flump.executor.Executor;
import flump.executor.Future;

import com.threerings.util.F;
import com.threerings.util.StringUtil;

public class Files
{
    public static function load (file :File, exec :Executor=null) :Future {
        if (!exec) exec = new Executor(1);
        return exec.submit(function (onSuccess :Function, onError :Function) :void {
            // Check for non-existence specifically. It'll fire an IO_ERROR, but that error just
            // says "Error #2038", which isn't very helpful.
            if (!file.exists) {
                onError(new Error(file.nativePath + " doesn't exist to load"));
                return;
            }
            file.addEventListener(Event.COMPLETE, F.callback(onSuccess, file));
            file.addEventListener(IOErrorEvent.IO_ERROR, onError);
            file.load();
        });
    }

    public static function list (dir :File, exec :Executor) :Future {
        return exec.submit(function (onSuccess :Function, onError :Function) :void {
            // Be anal about clearing out the listeners on both callbacks in case this directory is
            // listed again.
            function clearListeners () :void {
                dir.removeEventListener(FileListEvent.DIRECTORY_LISTING, wrangleFiles);
                dir.removeEventListener(ErrorEvent.ERROR, handleError);
            }
            function wrangleFiles (ev :FileListEvent) :void {
                clearListeners();
                onSuccess(ev.files);
            }
            function handleError (ev :ErrorEvent) :void {
                clearListeners();
                onError(ev);
            }
            dir.addEventListener(FileListEvent.DIRECTORY_LISTING, wrangleFiles);
            dir.addEventListener(ErrorEvent.ERROR, handleError);
            dir.getDirectoryListingAsync();
        });
    }

    public static function hasExtension (file :File, ext :String) :Boolean {
        return !file.isHidden && StringUtil.endsWith(file.nativePath, "."+ext);
    }

    public static function getExtension (file :File) :String {
        const path :String = file.nativePath;
        return path.substr(path.lastIndexOf(".") + 1).toLowerCase();
    }
}
}
