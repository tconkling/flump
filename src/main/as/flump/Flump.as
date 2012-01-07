//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.desktop.NativeApplication;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.InvokeEvent;
import flash.filesystem.File;

import deng.fzip.FZip;
import deng.fzip.FZipFile;

import flump.xfl.Animation;

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
        const file :File = new File(invoke.arguments[0])
        log.info("Loading", "file", file, "fn", invoke.arguments[0]);
        file.addEventListener(Event.COMPLETE, F.callback(onLoaded, file));
        file.addEventListener(IOErrorEvent.IO_ERROR, function (err :IOErrorEvent) :void {
            log.warning("Error loading", "fla", invoke.arguments[0], "error", err);
            NA.exit(1);
        });
        file.load();
    }

    protected function onLoaded (file :File) :void {
        const zip :FZip = new FZip();
        zip.loadBytes(file.data);
        const files :Array = [];
        for (var ii :int = 0; ii < zip.getFileCount(); ii++) {
            files.push(zip.getFileAt(ii));
        }
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
            new Animation(new XML(fz.content.readUTFBytes(fz.content.length)));
        }
        NA.exit(0);
    }

    private static const log :Log = Log.getLog(Flump);
}}
