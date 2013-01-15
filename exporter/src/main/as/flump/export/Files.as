//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.FileListEvent;
import flash.events.IOErrorEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;

import flump.executor.Executor;
import flump.executor.Future;

import com.threerings.util.F;
import com.threerings.util.StringUtil;

public class Files
{
    public static function load (file :File, exec :Executor=null) :Future {
        if (!exec) exec = new Executor();
        return exec.submit(function (onSuccess :Function, onError :Function) :void {
            // Check for non-existence specifically. It'll fire an IO_ERROR, but that error just
            // says "Error #2038", which isn't very helpful.
            if (!file.exists) {
                onError(new Error(file.nativePath + " doesn't exist to load"));
                return;
            }

            var stream :FileStream = new FileStream();
            stream.addEventListener(Event.COMPLETE, function (_:*) :void {
                var data :ByteArray = new ByteArray();
                stream.readBytes(data);
                stream.close();
                onSuccess(data);
            });
            stream.addEventListener(IOErrorEvent.IO_ERROR, onError);
            stream.openAsync(file, "read");
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

    public static function read (file :File) :ByteArray {
        var stream :FileStream = new FileStream();
        stream.open(file, FileMode.READ);
        var bytes :ByteArray = new ByteArray();
        stream.readBytes(bytes);
        stream.close();
        return bytes;
    }

    public static function write (file :File, writer :Function) :void {
        const out :FileStream = new FileStream();
        out.open(file, FileMode.WRITE);
        writer(out);
        out.close();
    }

    public static function hasExtension (file :File, ext :String) :Boolean {
        return !file.isHidden && StringUtil.endsWith(file.nativePath, "." + ext);
    }

    public static function getExtension (file :File) :String {
        const path :String = file.nativePath;
        return path.substr(path.lastIndexOf(".") + 1).toLowerCase();
    }

    public static function replaceExtension (file :File, ext :String) :String {
        const path :String = file.nativePath;
        return path.substr(0, path.lastIndexOf(".") + 1) + ext;
    }
}
}
