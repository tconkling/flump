//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.desktop.NativeApplication;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filesystem.File;
import flash.net.SharedObject;

import deng.fzip.FZip;
import deng.fzip.FZipFile;

import executor.Executor;
import executor.Future;

import flump.xfl.XflAnimation;
import flump.xfl.XflLibrary;

import spark.components.List;
import spark.components.Window;
import spark.events.IndexChangeEvent;

import starling.core.Starling;

import com.threerings.util.F;
import com.threerings.util.Log;
import com.threerings.util.StringUtil;

public class Exporter
{
    public static const NA :NativeApplication = NativeApplication.nativeApplication;

    protected static const IMPORT_ROOT :String = "IMPORT_ROOT";

    public function Exporter (win :ExportWindow) {
        _win = win;
        _libraries = _win.libraries;
        _libraries.addEventListener(IndexChangeEvent.CHANGE, function (..._) :void {
            _win.export.enabled = _libraries.selectedIndices.length > 0;
        });
        _win.export.addEventListener(MouseEvent.CLICK, function (..._) :void {
            for each (var file :File in _libraries.selectedItems) loadFlashDocument(file);
        });
        _importChooser =
            new DirChooser(_settings, "IMPORT_ROOT", _win.importRoot, _win.browseImport);
        _importChooser.changed.add(setImport);
        setImport(new File(_importChooser.dir));
        _exportChooser =
            new DirChooser(_settings, "EXPORT_ROOT", _win.exportRoot, _win.browseExport);
    }

    protected function setImport (root :File) :void {
        _libraries.dataProvider.removeAll();
        const rootLen :int = root.nativePath.length + 1;
        _libraries.labelFunction = function (file :File) :String {
            return file.nativePath.substring(rootLen);
        };
        if (_docFinder != null) _docFinder.shutdownNow();
        _docFinder = new Executor(2);
        findFlashDocuments(root, _docFinder);
    }

    protected function findFlashDocuments (base :File, exec :Executor) :void {
        Files.list(base, exec).succeeded.add(function (files :Array) :void {
            if (exec.isShutdown) return;
            for each (var file :File in files) {
                if (StringUtil.endsWith(file.nativePath, ".xfl")) {
                    addFlashDocument(file.parent);
                    return;
                }
            }
            for each (file in files) {
                if (file.isDirectory) findFlashDocuments(file, exec);
                else if (StringUtil.endsWith(file.nativePath, ".fla")) addFlashDocument(file);
            }
        });
    }

    protected function addFlashDocument (file :File) :void {
        _libraries.dataProvider.addItem(file);
        //loadFlashDocument(file);
    }

    protected function loadFlashDocument (file :File) :void {
        if (StringUtil.endsWith(file.nativePath, ".xfl")) file = file.parent;
        if (file.isDirectory) {
            const overseer :Overseer = new Overseer();
            const name :String = file.nativePath.substring(_importChooser.dir.length + 1);
            const load :Future = new XflLoader().load(name, file, overseer);
            load.succeeded.add(function (lib :XflLibrary) :void {
                for each (var item :Array in overseer.failures.items()) {
                    trace("Failures in " + item[0]);
                    for each (var failure :Array in item[1]) {
                        trace("  " + failure);
                    }
                }
                for each (item in overseer.successes.items()) {
                    trace(item[0] + ": " + item[1]);
                }
                PngExporter.dumpTextures(new File(_exportChooser.dir), lib);
                new BetwixtExporter().export(lib, file, new File(_exportChooser.dir));
                Preview(Starling.current.stage.getChildAt(0)).displayAnimation(file, lib, lib.animations[0]);
            });
        } else loadFla(file);
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
                new XflAnimation(bytesToXML(fz.content));
            }
            NA.exit(0);
        });
    }

    protected var _docFinder :Executor;
    protected var _win :ExportWindow;
    protected var _libraries :List;
    protected var _exportChooser :DirChooser;
    protected var _importChooser :DirChooser;
    protected const _settings :SharedObject = SharedObject.getLocal("flump/Exporter");

    private static const log :Log = Log.getLog(Exporter);
}
}
