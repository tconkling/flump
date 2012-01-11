//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.desktop.NativeApplication;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.InvokeEvent;
import flash.filesystem.File;

import deng.fzip.FZip;
import deng.fzip.FZipFile;

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
        if (file.isDirectory) new XflLoader().load(file).succeeded.add(function (lib :Library) :void {
            PngExporter.dumpTextures(file, lib);
        });
        else loadFla(file);
    }

    protected function loadFla (file :File) :void {
        log.info("Loading fla", "path", file.nativePath);
        Files.load(file).succeeded.add(function (file :File) :void {
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

    private static const log :Log = Log.getLog(Flump);
}}
