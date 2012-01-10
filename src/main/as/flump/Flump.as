//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.desktop.NativeApplication;
import flash.display.Sprite;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.FileListEvent;
import flash.events.IOErrorEvent;
import flash.events.InvokeEvent;
import flash.filesystem.File;
import flash.utils.ByteArray;

import deng.fzip.FZip;
import deng.fzip.FZipFile;

import executor.Executor;
import executor.Future;

import flump.xfl.Animation;
import flump.xfl.Library;
import flump.xfl.Texture;

import com.threerings.util.F;
import com.threerings.util.Log;
import com.threerings.util.StringUtil;

public class Flump extends Sprite
{
    public static const NA :NativeApplication = NativeApplication.nativeApplication;

    public function Flump () {
        NA.addEventListener(InvokeEvent.INVOKE, onInvoke);
    }

    protected function onInvoke (invoke :InvokeEvent) :void {
        const file :File = new File(invoke.arguments[0]);
        if (!file.exists) {
            log.error("Given file doesn't exist", "path", file.nativePath);
            NA.exit(1);
            return;
        }
        loadFlashDocument(file);
    }

    protected function loadFlashDocument (file :File) :void {
        if (StringUtil.endsWith(file.nativePath, ".xfl")) file = file.parent;
        if (file.isDirectory) loadXfl(file);
        else loadFla(file);
    }

    protected function loadXfl (file :File) :void {
        log.info("Loading xfl", "path", file.nativePath);
        const lister :Executor = new Executor();
        const loader :Executor = new Executor();
        const library :Library = new Library();
        list(file.resolvePath("LIBRARY/Animations"), lister).succeeded.add(function (animFiles :Array) :void {
            for each (var anim :File in animFiles) {
                loadFile(anim,  loader).succeeded.add(function (f :File) :void {
                    library.animations.push(new Animation(bytesToXML(f.data)));
                });
            }
        });
        list(file.resolvePath("LIBRARY/Textures"), lister).succeeded.add(function (texFiles :Array) :void {
            for each (var tex: File in texFiles) {
                loadFile(tex, loader).succeeded.add(function (f :File) :void {
                    library.textures.push(new Texture(bytesToXML(f.data)));
                });
            }
        });
        // TODO - construct the swf path for realz
        new SwfLoader().loadFromFile(new File(file.nativePath + ".swf"), loader).succeeded.add(
            function (swf :Swf) :void { library.swf = swf; });
        lister.terminated.add(F.callback(loader.shutdown));
        loader.terminated.add(function (..._) :void {
            trace("Loaded " + library.animations + " " + library.textures + " " + library.swf);
            NA.exit(0);
        });
        lister.shutdown();
    }

    protected function loadFla (file :File) :void {
        log.info("Loading fla", "path", file.nativePath);
        loadFile(file).succeeded.add(function (file :File) :void {
            const zip :FZip = new FZip();
            zip.loadBytes(file.data);
            const files :Array = [];
            for (var ii :int = 0; ii < zip.getFileCount(); ii++) files.push(zip.getFileAt(ii));
            const xmls :Array = F.filter(files, function (fz :FZipFile) :Boolean {
                return StringUtil.endsWith(fz.filename, ".xml");
            });
            const anims :Array = F.filter(xmls, function (fz :FZipFile) :Boolean {
                return StringUtil.startsWith(fz.filename, "LIBRARY/Animations/");
            });
            const textures :Array = F.filter(xmls, function (fz :FZipFile) :Boolean {
                return StringUtil.startsWith(fz.filename, "LIBRARY/Textures/");
            });
            function toFn (fz :FZipFile) :String { return fz.filename };
            log.info("Loaded", "bytes", file.data.length, "anims", F.map(anims, toFn),
                "textures", F.map(textures, toFn));
            for each (var fz :FZipFile in anims) {
                new Animation(bytesToXML(fz.content));
            }
            NA.exit(0);
        });
    }

    protected static function bytesToXML (bytes :ByteArray) :XML {
       return new XML(bytes.readUTFBytes(bytes.length));
    }

    protected static function loadFile (file :File, exec :Executor=null) :Future {
        if (!exec) exec = new Executor();
        return exec.submit(function (onSuccess :Function, onError :Function) :void {
            file.addEventListener(Event.COMPLETE, F.callback(onSuccess, file));
            file.addEventListener(IOErrorEvent.IO_ERROR, onError);
            file.load();
        });
    }

    protected static function list (dir :File, exec :Executor) :Future {
        return exec.submit(function (onSuccess :Function, onError :Function) :void {
            dir.addEventListener(FileListEvent.DIRECTORY_LISTING,
                function (ev :FileListEvent) :void { onSuccess(ev.files) });
            dir.addEventListener(ErrorEvent.ERROR, onError);
            dir.getDirectoryListingAsync();
        });
    }

    private static const log :Log = Log.getLog(Flump);
}}
