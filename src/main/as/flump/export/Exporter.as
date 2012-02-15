//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

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

import flump.bytesToXML;
import flump.export.Ternary;
import flump.xfl.ParseError;
import flump.xfl.XflAnimation;
import flump.xfl.XflLibrary;

import spark.components.DataGrid;
import spark.components.List;
import spark.components.Window;
import spark.events.GridSelectionEvent;

import starling.core.Starling;

import com.threerings.util.DelayUtil;
import com.threerings.util.F;
import com.threerings.util.Log;
import com.threerings.util.StringUtil;

public class Exporter
{
    public static const NA :NativeApplication = NativeApplication.nativeApplication;

    protected static const IMPORT_ROOT :String = "IMPORT_ROOT";

    public function Exporter (win :ExporterWindow) {
        _win = win;
        _errors = _win.errors;
        _libraries = _win.libraries;
        _libraries.addEventListener(GridSelectionEvent.SELECTION_CHANGE, function (..._) :void {
            log.info("Changed", "selected", _libraries.selectedIndices);
            _win.export.enabled = _libraries.selectedIndices.length > 0;
            _win.preview.enabled = _libraries.selectedIndices.length == 1;
        });
        _win.export.addEventListener(MouseEvent.CLICK, function (..._) :void {
            for each (var status :DocStatus in _libraries.selectedItems) {
                exportFlashDocument(status);
            }
        });
        _win.preview.addEventListener(MouseEvent.CLICK, function (..._) :void {
            var previewWindow :PreviewWindow = new PreviewWindow();
            previewWindow.started = F.callback(DelayUtil.delayFrame, function (..._) :void {

                var preview :Preview = Preview(Starling.current.stage.getChildAt(0));
                var lib :XflLibrary = _libraries.selectedItem.lib;
                // TODO - animation selector in Preview
            });
            previewWindow.open();
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
        const status :DocStatus = new DocStatus(file, _rootLen, Ternary.UNKOWN, Ternary.UNKOWN, null);
        _libraries.dataProvider.addItem(status);
        loadFlashDocument(status);
    }

    protected function exportFlashDocument (status :DocStatus) :void {
        const exportDir :File = new File(_exportChooser.dir);
        PngPublisher.dumpTextures(exportDir, status.lib);
        BetwixtPublisher.export(status.lib, status.file, exportDir);
        status.updateModified(Ternary.FALSE);
    }

    protected function loadFlashDocument (status :DocStatus) :void {
        if (StringUtil.endsWith(status.file.nativePath, ".xfl")) status.file = status.file.parent;
        if (status.file.isDirectory) {
            const name :String = status.file.nativePath.substring(_rootLen);
            const load :Future = new XflLoader().load(name, status.file);
            load.succeeded.add(function (lib :XflLibrary) :void {
                const exportDir :File = new File(_exportChooser.dir);
                const isMod :Boolean = BetwixtPublisher.modified(lib, exportDir);
                status.lib = lib;
                status.updateModified(Ternary.of(isMod));
                for each (var err :ParseError in lib.getErrors()) {
                    _errors.dataProvider.addItem(err);
                    trace(err);
                }
                status.updateValid(Ternary.of(lib.valid));
                if (status.path == "shapes") {
                    try {
                        exportFlashDocument(status);
                    } catch (e :Error) {
                        log.warning("Blew up", e);
                    } finally {
                        NA.exit(0);
                    }
                }
            });
        } else loadFla(status.file);
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
                new XflAnimation(fz.filename, bytesToXML(fz.content), MD5.hashBytes(fz.content));
            }
            NA.exit(0);
        });
    }

    protected var _rootLen :int;

    protected var _docFinder :Executor;
    protected var _win :ExporterWindow;
    protected var _libraries :DataGrid;
    protected var _errors :DataGrid;
    protected var _exportChooser :DirChooser;
    protected var _importChooser :DirChooser;
    protected const _settings :SharedObject = SharedObject.getLocal("flump/Exporter");

    private static const log :Log = Log.getLog(Exporter);
}
}
import flash.events.EventDispatcher;
import flash.filesystem.File;

import flump.export.Ternary;
import flump.xfl.XflLibrary;

import mx.core.IPropertyChangeNotifier;
import mx.events.PropertyChangeEvent;

class DocStatus extends EventDispatcher implements IPropertyChangeNotifier {
    public var path :String;
    public var modified :String;
    public var valid :String = QUESTION;
    public var file :File;
    public var lib :XflLibrary;

    public function DocStatus (file :File, rootLen :int, modified :Ternary, valid :Ternary, lib :XflLibrary) {
        this.file = file;
        this.lib = lib;
        path = file.nativePath.substring(rootLen);
        _uid = path;

        updateModified(modified);
        updateValid(valid);
    }

    public function updateValid (newValid :Ternary) :void {
        changeField("valid", function (..._) :void {
            if (newValid == Ternary.TRUE) valid = CHECK;
            else if (newValid == Ternary.FALSE) valid = FROWN;
            else valid = QUESTION;
        });
    }

    public function updateModified (newModified :Ternary) :void {
        changeField("modified", function (..._) :void {
            if (newModified == Ternary.TRUE) modified = CHECK;
            else if (newModified == Ternary.FALSE) modified = " ";
            else modified = QUESTION;
        });
    }

    protected function changeField(fieldName :String, modifier :Function) :void {
        const oldValue :Object = this[fieldName];
        modifier();
        const newValue :Object = this[fieldName];
        dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, fieldName, oldValue, newValue));
    }

    public function get uid () :String { return _uid; }
    public function set uid (uid :String) :void { _uid = uid; }

    protected var _uid :String;

    protected static const QUESTION :String = "?";
    protected static const FROWN :String = "☹";
    protected static const CHECK :String = "✓";
}
