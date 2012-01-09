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

import flump.xfl.Animation;
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
        list(file.resolvePath("LIBRARY/Animations"), function (animFiles :Array) :void {
            for each (var anim :File in animFiles) {
                loadFile(anim,  function (f :File) :void { new Animation(bytesToXML(f.data)); });
            }
        });
        list(file.resolvePath("LIBRARY/Textures"), function (texFiles :Array) :void {
            for each (var tex: File in texFiles) {
                loadFile(tex, function (f :File) :void { new Texture(bytesToXML(f.data)); });
            }
        });
    }

    protected function loadFla (file :File) :void {
        log.info("Loading fla", "path", file.nativePath);
        loadFile(file, function (file :File) :void {
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

    protected static function loadFile (file :File, onLoaded :Function) :void {
        file.addEventListener(Event.COMPLETE, F.callback(onLoaded, file));
        file.addEventListener(IOErrorEvent.IO_ERROR, function (err :IOErrorEvent) :void {
            log.warning("Error loading", "file", file.nativePath, "error", err);
            NA.exit(1);
        });
        file.load();
    }

    protected static function list (dir :File, onListed :Function) :void {
        dir.addEventListener(FileListEvent.DIRECTORY_LISTING, function (ev :FileListEvent) :void {
            onListed(ev.files);
        });
        dir.addEventListener(ErrorEvent.ERROR, function (err :ErrorEvent) :void {
            log.warning("Error listing", "dir", dir.nativePath, "error", err);
            NA.exit(1);
        });
        dir.getDirectoryListingAsync();
    }

    private static const log :Log = Log.getLog(Flump);
}}
