//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.desktop.NativeApplication;
import flash.display.NativeWindow;
import flash.display.Stage;
import flash.display.StageQuality;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filesystem.File;
import flash.net.SharedObject;

import com.adobe.crypto.MD5;

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

import mx.collections.ArrayCollection;

import spark.components.DataGrid;
import spark.components.DropDownList;
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
    protected static const AUTHORED_RESOLUTION :String = "AUTHORED_RESOLUTION";

    public function Exporter (win :ExporterWindow) {
        _win = win;
        _errors = _win.errors;
        _libraries = _win.libraries;

        _authoredResolution = _win.authoredResolutionPopup;
        _authoredResolution.dataProvider = new ArrayCollection(DeviceType.values().map(
            function (type :DeviceType, ..._) :Object {
                return new DeviceSelection(type);
            }));
        var initialSelection :DeviceType = null;
        if (_settings.data.hasOwnProperty(AUTHORED_RESOLUTION)) {
            try {
                initialSelection = DeviceType.valueOf(_settings.data[AUTHORED_RESOLUTION]);
            } catch (e :Error) {}
        }
        if (initialSelection == null) {
            initialSelection = DeviceType.IPHONE_RETINA;
        }
        _authoredResolution.selectedIndex = DeviceType.values().indexOf(initialSelection);
        _authoredResolution.addEventListener(Event.CHANGE, function (..._) :void {
            var selectedType :DeviceType = DeviceSelection(_authoredResolution.selectedItem).type;
            _settings.data[AUTHORED_RESOLUTION] = selectedType.name();
        });

        function updateExportEnabled (..._) :void {
            _win.export.enabled = _exportChooser.dir != null && _libraries.selectionLength > 0 &&
              _libraries.selectedItems.some(function (status :DocStatus, ..._) :Boolean {
                return status.isValid;
            });
        }
        _libraries.addEventListener(GridSelectionEvent.SELECTION_CHANGE, function (..._) :void {
            log.info("Changed", "selected", _libraries.selectedIndices);
            updateExportEnabled();
            _win.preview.enabled = _libraries.selectedItem.isValid;
        });
        _win.reload.addEventListener(MouseEvent.CLICK, function (..._) :void {
            setImport(_importChooser.dir);
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
        function updatePublisher (..._) :void {
            if (_exportChooser.dir == null) _publisher = null;
            else {
                _publisher =
                    new Publisher(_exportChooser.dir, new XMLFormat(), new JSONFormat(), new StarlingFormat());
            }
        };
        _exportChooser.changed.add(updatePublisher);
        updatePublisher();
        _win.addEventListener(Event.CLOSE, function (..._) :void { NA.exit(0); });
    }

    protected function setImport (root :File) :void {
        _libraries.dataProvider.removeAll();
        _errors.dataProvider.removeAll();
        if (root == null) return;
        _rootLen = root.nativePath.length + 1;
        if (_docFinder != null) _docFinder.shutdownNow();
        _docFinder = new Executor(2);
        findFlashDocuments(root, _docFinder, true);
        _win.reload.enabled = true;
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

    protected function findFlashDocuments (
            base :File, exec :Executor, ignoreXflAtBase :Boolean = false) :void {
        Files.list(base, exec).succeeded.add(function (files :Array) :void {
            if (exec.isShutdown) return;
            for each (var file :File in files) {
                if (Files.hasExtension(file, "xfl")) {
                    if (ignoreXflAtBase) {
                        _errors.dataProvider.addItem(new ParseError(base.nativePath,
                            ParseError.CRIT, "The import directory can't be an XFL directory, did you mean " +
                            base.parent.nativePath + "?"));
                    } else {
                        addFlashDocument(file.parent);
                    }
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

        var stage :Stage = NA.activeWindow.stage;
        var prevQuality :String = stage.quality;

        stage.quality = StageQuality.BEST;
        _publisher.publish(status.lib, DeviceSelection(_authoredResolution.selectedItem).type);

        stage.quality = prevQuality;
        status.updateModified(Ternary.FALSE);
    }

    protected function loadFlashDocument (status :DocStatus) :void {
        if (Files.hasExtension(status.file, "xfl")) status.file = status.file.parent;
        if (status.file.isDirectory) {
            const name :String = status.file.nativePath
                .substring(_rootLen).replace(File.separator, "/");
            const load :Future = new XflLoader().load(name, status.file);
            load.succeeded.add(function (lib :XflLibrary) :void {
                status.lib = lib;
                status.updateModified(Ternary.of(_publisher == null || _publisher.modified(lib)));
                for each (var err :ParseError in lib.getErrors()) _errors.dataProvider.addItem(err);
                status.updateValid(Ternary.of(lib.valid));
            });
            load.failed.add(function (e :Error) :void {
                trace("Failed to load " + status.file.nativePath + ":" + e);
                status.updateValid(Ternary.FALSE);
                throw e;
            });
        } else loadFla(status.file);
    }

    protected function loadFla (file :File) :void {
        log.info("fla support not implemented", "path", file.nativePath);
        return;
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
                XflMovie.parse(null, bytesToXML(fz.content), MD5.hashBytes(fz.content));
            }
            NA.exit(0);
        });
    }

    protected var _rootLen :int;

    protected var _publisher :Publisher;
    protected var _docFinder :Executor;
    protected var _win :ExporterWindow;
    protected var _libraries :DataGrid;
    protected var _errors :DataGrid;
    protected var _exportChooser :DirChooser;
    protected var _importChooser :DirChooser;
    protected var _authoredResolution :DropDownList;
    protected const _settings :SharedObject = SharedObject.getLocal("flump/Exporter");

    private static const log :Log = Log.getLog(Exporter);
}
}
import flump.export.DeviceType;

class DeviceSelection {
    public var type :DeviceType;
    public function DeviceSelection (type :DeviceType) {
        this.type = type;
    }
    public function toString () :String {
        return type.displayName + " (" + type.resWidth + "x" + type.resHeight + ")";
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
