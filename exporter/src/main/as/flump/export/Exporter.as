//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.desktop.NativeApplication;
import flash.display.NativeWindow;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filesystem.File;
import flash.net.SharedObject;

import deng.fzip.FZip;
import deng.fzip.FZipFile;

import flump.bytesToXML;
import flump.display.Movie;
import flump.executor.Executor;
import flump.executor.Future;
import flump.export.Ternary;
import flump.xfl.ParseError;
import flump.xfl.XflLibrary;
import flump.xfl.XflMovie;

import spark.components.DataGrid;
import spark.components.List;
import spark.components.Window;
import spark.events.GridSelectionEvent;

import starling.display.Sprite;

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
        function updateExportEnabled (..._) :void {
            _win.export.enabled = _exportChooser.dir != null &&
              _libraries.selectedItems.some(function (status :DocStatus, ..._) :Boolean {
                return status.isValid;
            });
        }
        _libraries.addEventListener(GridSelectionEvent.SELECTION_CHANGE, function (..._) :void {
            log.info("Changed", "selected", _libraries.selectedIndices);
            updateExportEnabled();
            _win.preview.enabled = _libraries.selectedItem.isValid;
        });
        _win.export.addEventListener(MouseEvent.CLICK, function (..._) :void {
            for each (var status :DocStatus in _libraries.selectedItems) {
                exportFlashDocument(status);
            }
        });
        _win.preview.addEventListener(MouseEvent.CLICK, function (..._) :void {
            showPreviewWindow(_libraries.selectedItem.lib);
        });
        _importChooser =
            new DirChooser(_settings, "IMPORT_ROOT", _win.importRoot, _win.browseImport);
        _importChooser.changed.add(setImport);
        setImport(_importChooser.dir);
        _exportChooser =
            new DirChooser(_settings, "EXPORT_ROOT", _win.exportRoot, _win.browseExport);
        _exportChooser.changed.add(updateExportEnabled);

    }

    protected function setImport (root :File) :void {
        _libraries.dataProvider.removeAll();
        _errors.dataProvider.removeAll();
        if (root == null) return;
        _rootLen = root.nativePath.length + 1;
        if (_docFinder != null) _docFinder.shutdownNow();
        _docFinder = new Executor(2);
        findFlashDocuments(root, _docFinder);
    }

    protected function showPreviewWindow (lib :XflLibrary) :void {
        if (_previewController == null || _previewWindow.closed || _previewControls.closed) {
            _previewWindow = new PreviewWindow();
            _previewControls = new PreviewControlsWindow();
            _previewWindow.started = function (container :Sprite) :void {
                _previewController = new PreviewController(lib, container, _previewControls);
            }
            
            _previewWindow.open();
            _previewControls.open();
            
            preventWindowClose(_previewWindow.nativeWindow);
            preventWindowClose(_previewControls.nativeWindow);
            
        } else {
            _previewController.lib = lib;
            _previewWindow.nativeWindow.visible = true;
            _previewControls.nativeWindow.visible = true;
        }
    }
    
    // Causes a window to be hidden, rather than closed, when its close box is clicked
    protected static function preventWindowClose (window :NativeWindow) :void {
        window.addEventListener(Event.CLOSING, function (e :Event) :void {
            e.preventDefault();
            window.visible = false;
        });
    }

    protected var _previewController :PreviewController;
    protected var _previewWindow :PreviewWindow;
    protected var _previewControls :PreviewControlsWindow;

    protected function findFlashDocuments (base :File, exec :Executor) :void {
        Files.list(base, exec).succeeded.add(function (files :Array) :void {
            if (exec.isShutdown) return;
            for each (var file :File in files) {
                if (Files.hasExtension(file, "xfl")) {
                    addFlashDocument(file.parent);
                    return;
                }
            }
            for each (file in files) {
                if (file.isDirectory) findFlashDocuments(file, exec);
                else if (Files.hasExtension(file, "fla")) addFlashDocument(file);
            }
        });
    }

    protected function addFlashDocument (file :File) :void {
        const status :DocStatus = new DocStatus(file, _rootLen, Ternary.UNKNOWN, Ternary.UNKNOWN, null);
        _libraries.dataProvider.addItem(status);
        loadFlashDocument(status);
    }

    protected function exportFlashDocument (status :DocStatus) :void {
        BetwixtPublisher.publish(status.lib, status.file, _exportChooser.dir);
        status.updateModified(Ternary.FALSE);
    }

    protected function loadFlashDocument (status :DocStatus) :void {
        if (Files.hasExtension(status.file, "xfl")) status.file = status.file.parent;
        if (status.file.isDirectory) {
            const name :String = status.file.nativePath.substring(_rootLen);
            const load :Future = new XflLoader().load(name, status.file);
            load.succeeded.add(function (lib :XflLibrary) :void {
                // Don't blow up if the export directory hasn't been chosen
                var isMod :Boolean = true;
                if (_exportChooser.dir != null) {
                    var metadata :File = _exportChooser.dir.resolvePath(
                        lib.location + "/resources.xml");
                    isMod = BetwixtPublisher.modified(lib, metadata);
                }
                status.lib = lib;
                status.updateModified(Ternary.of(isMod));
                for each (var err :ParseError in lib.getErrors()) {
                    _errors.dataProvider.addItem(err);
                    trace(err);
                }
                status.updateValid(Ternary.of(lib.valid));
                if (false && status.path == "guybrush") {
                    try {
                        showPreviewWindow(lib);
                        //exportFlashDocument(status);
                    } catch (e :Error) {
                        log.warning("Blew up", e);
                    } finally {
                        //NA.exit(0);
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
            const movies :Array = F.filter(xmls, function (fz :FZipFile) :Boolean {
                return StringUtil.startsWith(fz.filename, "LIBRARY/Animations/");
            });
            const textures :Array = F.filter(xmls, function (fz :FZipFile) :Boolean {
                return StringUtil.startsWith(fz.filename, "LIBRARY/Textures/");
            });
            function toFn (fz :FZipFile) :String { return fz.filename };
            log.info("Loaded", "bytes", file.data.length, "movies", F.map(movies, toFn),
                "textures", F.map(textures, toFn));
            for each (var fz :FZipFile in movies) {
                new XflMovie(fz.filename, bytesToXML(fz.content));
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

    public function get isValid () :Boolean { return valid == CHECK; }

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
