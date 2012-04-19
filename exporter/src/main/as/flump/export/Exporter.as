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

import flump.bytesToXML;
import flump.display.Movie;
import flump.executor.Executor;
import flump.executor.Future;
import flump.export.Ternary;
import flump.xfl.ParseError;
import flump.xfl.XflLibrary;
import flump.xfl.XflMovie;

import mx.collections.ArrayCollection;
import mx.events.PropertyChangeEvent;

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
        Log.setLevel("", Log.INFO);
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
        if (initialSelection == null) initialSelection = DeviceType.IPHONE_RETINA;
        _authoredResolution.selectedIndex = DeviceType.values().indexOf(initialSelection);
        _authoredResolution.addEventListener(Event.CHANGE, function (..._) :void {
            var selectedType :DeviceType = DeviceSelection(_authoredResolution.selectedItem).type;
            _settings.data[AUTHORED_RESOLUTION] = selectedType.name();
        });

        function updatePreviewAndExport (..._) :void {
            _win.export.enabled = _exportChooser.dir != null && _libraries.selectionLength > 0 &&
                _libraries.selectedItems.some(function (status :DocStatus, ..._) :Boolean {
                    return status.isValid;
            });

            var status :DocStatus = _libraries.selectedItem as DocStatus;
            _win.preview.enabled = (status != null && status.isValid);
        }

        var curSelection :DocStatus = null;
        _libraries.addEventListener(GridSelectionEvent.SELECTION_CHANGE, function (..._) :void {
            log.info("Changed", "selected", _libraries.selectedIndices);
            updatePreviewAndExport();

            if (curSelection != null) {
                curSelection.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, updatePreviewAndExport);
            }
            var newSelection :DocStatus = _libraries.selectedItem as DocStatus;
            if (newSelection != null) {
                newSelection.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, updatePreviewAndExport);
            }
            curSelection = newSelection;
        });
        _win.reload.addEventListener(MouseEvent.CLICK, function (..._) :void {
            setImport(_importChooser.dir);
            updatePreviewAndExport();
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
        _exportChooser.changed.add(updatePreviewAndExport);
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
        _docFinder = new Executor(1);
        findFlashDocuments(root, _docFinder, true);
        _win.reload.enabled = true;
    }

    protected function showPreviewWindow (lib :XflLibrary) :void {
        if (_previewController == null || _previewWindow.closed || _previewControls.closed) {
            _previewWindow = new PreviewWindow();
            _previewControls = new PreviewControlsWindow();
            _previewWindow.started = function (container :Sprite) :void {
                _previewController = new PreviewController(lib, container, _previewWindow,
                    _previewControls);
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

    protected function findFlashDocuments (base :File, exec :Executor,
        ignoreXflAtBase :Boolean = false) :void {
        Files.list(base, exec).succeeded.add(function (files :Array) :void {
            if (exec.isShutdown) return;
            for each (var file :File in files) {
                if (Files.hasExtension(file, "xfl")) {
                    if (ignoreXflAtBase) {
                        _errors.dataProvider.addItem(new ParseError(base.nativePath,
                            ParseError.CRIT, "The import directory can't be an XFL directory, did you mean " +
                            base.parent.nativePath + "?"));
                    } else addFlashDocument(file);
                    return;
                }
            }
            for each (file in files) {
                if (StringUtil.startsWith(file.name, ".", "RECOVER_")) {
                    continue; // Ignore hidden VCS directories, and recovered backups created by Flash
                }
                if (file.isDirectory) findFlashDocuments(file, exec);
                else addFlashDocument(file);
            }
        });
    }

    protected function exportFlashDocument (status :DocStatus) :void {
        const stage :Stage = NA.activeWindow.stage;
        const prevQuality :String = stage.quality;

        stage.quality = StageQuality.BEST;
        _publisher.publish(status.lib, DeviceSelection(_authoredResolution.selectedItem).type);

        stage.quality = prevQuality;
        status.updateModified(Ternary.FALSE);
    }

    protected function addFlashDocument (file :File) :void {
        var name :String = file.nativePath.substring(_rootLen).replace(File.separator, "/");
        var load :Future;
        switch (Files.getExtension(file)) {
        case "xfl":
            name = name.substr(0, name.lastIndexOf("/"));
            load = new XflLoader().load(name, file.parent);
            break;
        case "fla":
            name = name.substr(0, name.lastIndexOf("."));
            load = new FlaLoader().load(name, file);
            break;
        default:
            // Unsupported file type, ignore
            return;
        }

        const status :DocStatus = new DocStatus(name, _rootLen, Ternary.UNKNOWN, Ternary.UNKNOWN, null);
        _libraries.dataProvider.addItem(status);

        load.succeeded.add(function (lib :XflLibrary) :void {
            status.lib = lib;
            status.updateModified(Ternary.of(_publisher == null || _publisher.modified(lib)));
            for each (var err :ParseError in lib.getErrors()) _errors.dataProvider.addItem(err);
            status.updateValid(Ternary.of(lib.valid));
        });
        load.failed.add(function (error :Error) :void {
            trace("Failed to load " + file.nativePath + ": " + error);
            status.updateValid(Ternary.FALSE);
            throw error;
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
    public var lib :XflLibrary;

    public function DocStatus (path :String, rootLen :int, modified :Ternary, valid :Ternary, lib :XflLibrary) {
        this.lib = lib;
        this.path = path;
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
