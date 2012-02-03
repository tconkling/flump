//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.desktop.NativeApplication;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filesystem.File;
import flash.net.SharedObject;

import com.adobe.crypto.MD5;

import deng.fzip.FZip;
import deng.fzip.FZipFile;

import executor.Executor;
import executor.Future;

import flump.xfl.XflAnimation;
import flump.xfl.XflLibrary;

import spark.components.DataGrid;
import spark.components.List;
import spark.components.Window;
import spark.events.GridSelectionEvent;

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
        _libraries.addEventListener(GridSelectionEvent.SELECTION_CHANGE, function (..._) :void {
            log.info("Changed", "selected", _libraries.selectedIndices);
            _win.export.enabled = _libraries.selectedIndices.length > 0;
        });
        _win.export.addEventListener(MouseEvent.CLICK, function (..._) :void {
            for each (var docData :Object in _libraries.selectedItems) {
                exportFlashDocument(docData.lib, docData.file);
            }
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
        _rootLen = root.nativePath.length + 1;
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
        _libraries.dataProvider.addItem(new DocStatus(file, _rootLen, Ternary.UNKOWN, Ternary.UNKOWN, null));
        loadFlashDocument(file, _libraries.dataProvider.length - 1);
    }

    protected function exportFlashDocument (lib :XflLibrary, file :File) :void {
        const exportDir :File = new File(_exportChooser.dir);
        PngExporter.dumpTextures(exportDir, lib);
        BetwixtExporter.export(lib, file, exportDir);
    }

    protected function loadFlashDocument (file :File, idx :int) :void {
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
                const exportDir :File = new File(_exportChooser.dir);
                const modified :Boolean = BetwixtExporter.modified(lib, exportDir);
                _libraries.dataProvider.setItemAt(new DocStatus(file, _rootLen, Ternary.of(modified),
                    Ternary.of(overseer.failures.isEmpty()), lib), idx);
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
                new XflAnimation(bytesToXML(fz.content), MD5.hashBytes(fz.content));
            }
            NA.exit(0);
        });
    }


    protected var _rootLen :int;
    protected var _docFinder :Executor;
    protected var _win :ExportWindow;
    protected var _libraries :DataGrid;
    protected var _exportChooser :DirChooser;
    protected var _importChooser :DirChooser;
    protected const _settings :SharedObject = SharedObject.getLocal("flump/Exporter");

    private static const log :Log = Log.getLog(Exporter);
}
}

import flash.filesystem.File;

import flump.Ternary;
import flump.xfl.XflLibrary;

class DocStatus {
    public var path :String;
    public var modified :String = QUESTION;
    public var valid :String = QUESTION;
    public var file :File;
    public var lib :XflLibrary;

    public function DocStatus (file :File, rootLen :int, modified :Ternary, valid :Ternary, lib :XflLibrary) {
        this.file = file;
        this.lib = lib;
        path = file.nativePath.substring(rootLen);

        if (modified == Ternary.TRUE) this.modified = CHECK;
        else if (modified == Ternary.FALSE) this.modified = " ";

        if (valid == Ternary.TRUE) this.valid = CHECK;
        else if (valid == Ternary.FALSE) this.valid = FROWN;
    }

    protected static const QUESTION :String = "?";
    protected static const FROWN :String = "☹";
    protected static const CHECK :String = "✓";
}
