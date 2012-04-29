//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.desktop.NativeApplication;
import flash.display.NativeMenu;
import flash.display.NativeMenuItem;
import flash.display.NativeWindow;
import flash.display.Stage;
import flash.display.StageQuality;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filesystem.File;
import flash.net.SharedObject;
import flash.utils.IDataOutput;

import flump.executor.Executor;
import flump.executor.Future;
import flump.export.Ternary;
import flump.xfl.ParseError;
import flump.xfl.XflLibrary;

import mx.collections.ArrayList;
import mx.events.CollectionEvent;
import mx.events.PropertyChangeEvent;

import spark.components.DataGrid;
import spark.components.DropDownList;
import spark.components.List;
import spark.components.Window;
import spark.events.GridSelectionEvent;

import com.threerings.util.F;
import com.threerings.util.Log;
import com.threerings.util.StringUtil;

import starling.display.Sprite;

public class Exporter
{
    public static const NA :NativeApplication = NativeApplication.nativeApplication;

    public function Exporter (win :ExporterWindow) {
        Log.setLevel("", Log.INFO);
        _win = win;
        _errors = _win.errors;
        _libraries = _win.libraries;

        function updatePreviewAndExport (..._) :void {
            _win.export.enabled = _exportChooser.dir != null && _libraries.selectionLength > 0 &&
                _libraries.selectedItems.some(function (status :DocStatus, ..._) :Boolean {
                    return status.isValid;
            });


            var status :DocStatus = _libraries.selectedItem as DocStatus;
            _win.preview.enabled = status != null && status.isValid;

            if (_exportChooser.dir == null) return;
            _conf.exportDir = _confFile.parent.getRelativePath(_exportChooser.dir, /*useDotDot=*/true);
        }

        var fileMenuItem :NativeMenuItem;
        if (NativeApplication.supportsMenu) {
            // Grab the existing menu on macs. Use an index to get it as it's not going to be
            // 'File' in all languages
            fileMenuItem = NA.menu.getItemAt(1);
            // Add a separator before the existing close command
            fileMenuItem.submenu.addItemAt(new NativeMenuItem("Sep", /*separator=*/true), 0);
        } else {
            _win.nativeWindow.menu = new NativeMenu();
            fileMenuItem = _win.nativeWindow.menu.addSubmenu(new NativeMenu(), "File");
        }

        // Add save and save as by index to work with the existing items on Mac
        // Mac menus have an existing "Close" item, so everything we add should go ahead of that
        var newMenuItem :NativeMenuItem = fileMenuItem.submenu.addItemAt(new NativeMenuItem("New"), 0);
        newMenuItem.keyEquivalent = "n";
        newMenuItem.addEventListener(Event.SELECT, function (..._) :void {
            _confFile = null;
            _conf = new FlumpConf();
            updatePublisher();
        });
        var openMenuItem :NativeMenuItem =
            fileMenuItem.submenu.addItemAt(new NativeMenuItem("Open..."), 1);
        openMenuItem.keyEquivalent = "o";
        openMenuItem.addEventListener(Event.SELECT, function (..._) :void {
            var file :File = new File();
            file.addEventListener(Event.SELECT, function (..._) :void {
                _confFile = file;
                openConf();
                updatePublisher();
            });
            file.browseForOpen("Open Flump Configuration");
        });
        fileMenuItem.submenu.addItemAt(new NativeMenuItem("Sep", /*separator=*/true), 2);

        const saveMenuItem :NativeMenuItem =
            fileMenuItem.submenu.addItemAt(new NativeMenuItem("Save"), 3);
        saveMenuItem.keyEquivalent = "s";
        function saveConf () :void {
            Files.write(_confFile, function (out :IDataOutput) :void {
                // Set directories relative to where this file is being saved. Fall back to absolute
                // paths if relative paths aren't possible.
                if (_importChooser.dir != null) {
                    _conf.importDir = _confFile.parent.getRelativePath(_importChooser.dir, /*useDotDot=*/true);
                    if (_conf.importDir == null) _conf.importDir = _importChooser.dir.nativePath;
                }

                if (_exportChooser.dir != null) {
                    _conf.exportDir = _confFile.parent.getRelativePath(_exportChooser.dir, /*useDotDot=*/true);
                    if (_conf.exportDir == null) _conf.exportDir = _exportChooser.dir.nativePath;
                }

                out.writeUTFBytes(JSON.stringify(_conf, null, /*space=*/2));
            });
        };
        function saveAs (..._) :void {
            var file :File = new File();
            file.addEventListener(Event.SELECT, function (..._) :void {
                _confFile = file;
                trace("Conf file is now " + _confFile.nativePath);
                _settings.data["CONF_FILE"] = _confFile.nativePath;
                _settings.flush();
                saveConf();
            });
            file.browseForSave("Save Flump Configuration");
        };
        saveMenuItem.addEventListener(Event.SELECT, function (..._) :void {
            if (_confFile == null) saveAs();
            else saveConf();
        });

        function openConf () :void {
            try {
                _conf = FlumpConf.fromJSON(JSONFormat.readJSON(_confFile));
                _win.title = _confFile.name;
                var dir :String = _confFile.parent.nativePath + File.separator + _conf.importDir;
                setImport(new File(dir));
            } catch (e :Error) {
                log.warning("Unable to parse conf", e);
                _errors.dataProvider.addItem(new ParseError(_confFile.nativePath,
                    ParseError.CRIT, "Unable to read configuration"));
                _confFile = null;
            }
        };

        const saveAsMenuItem :NativeMenuItem =
            fileMenuItem.submenu.addItemAt(new NativeMenuItem("Save As..."), 4);
        saveAsMenuItem.keyEquivalent = "S";
        saveAsMenuItem.addEventListener(Event.SELECT, saveAs);

        if (_settings.data.hasOwnProperty("CONF_FILE")) {
            _confFile = new File(_settings.data["CONF_FILE"]);
            openConf();
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
        _importChooser = new DirChooser(null, _win.importRoot, _win.browseImport);
        _importChooser.changed.add(setImport);
        setImport(_importChooser.dir);
        _exportChooser = new DirChooser(null, _win.exportRoot, _win.browseExport);
        _exportChooser.changed.add(updatePreviewAndExport);
        function updatePublisher (..._) :void {
            if (_confFile != null) {
                _importChooser.dir = (_conf.importDir != null) ? _confFile.parent.resolvePath(_conf.importDir) : null;
                _exportChooser.dir = (_conf.exportDir != null) ? _confFile.parent.resolvePath(_conf.exportDir) : null;
            } else {
                _importChooser.dir = null;
                _exportChooser.dir = null;
            }
            if (_exportChooser.dir == null || _conf.exports.length == 0) _publisher = null;
            else _publisher = new Publisher(_exportChooser.dir, Vector.<ExportConf>(_conf.exports));

            var formatNames :Array = [];
            for each (var export :ExportConf in _conf.exports) formatNames.push(export.name);
            _win.formatOverview.text = formatNames.join(", ");
        };
        _exportChooser.changed.add(updatePublisher);

        var editFormats :EditFormatsWindow;
        _win.editFormats.addEventListener(MouseEvent.CLICK, function (..._) :void {
            if (editFormats == null || editFormats.closed) {
                editFormats = new EditFormatsWindow();
                editFormats.open();
            } else editFormats.orderToFront();

            var dataProvider :ArrayList = new ArrayList(_conf.exports);
            dataProvider.addEventListener(CollectionEvent.COLLECTION_CHANGE, updatePublisher);

            editFormats.exports.dataProvider = dataProvider;
            editFormats.buttonAdd.addEventListener(MouseEvent.CLICK, function (..._) :void {
                var export :ExportConf = new ExportConf();
                export.name = "format" + (_conf.exports.length+1);
                if (_conf.exports.length > 0) {
                    export.format = _conf.exports[0].format;
                }
                dataProvider.addItem(export);
            });
            editFormats.exports.addEventListener(GridSelectionEvent.SELECTION_CHANGE, function (..._) :void {
                editFormats.buttonRemove.enabled = (editFormats.exports.selectedItem != null);
            });
            editFormats.buttonRemove.addEventListener(MouseEvent.CLICK, function (..._) :void {
                for each (var export :ExportConf in editFormats.exports.selectedItems) {
                    dataProvider.removeItem(export);
                }
            });
        });

        updatePublisher();
        _win.addEventListener(Event.CLOSE, function (..._) :void { NA.exit(0); });
    }

    protected function setImport (root :File) :void {
        _libraries.dataProvider.removeAll();
        _errors.dataProvider.removeAll();
        if (root == null) return;
        _rootLen = root.nativePath.length + 1;
        if (_docFinder != null) _docFinder.shutdownNow();
        _docFinder = new Executor();
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

        _previewWindow.orderToFront();
        _previewControls.orderToFront();
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
        _publisher.publish(status.lib);

        stage.quality = prevQuality;
        status.updateModified(Ternary.FALSE);
    }

    protected function addFlashDocument (file :File) :void {
        var name :String = file.nativePath.substring(_rootLen).replace(
            new RegExp("\\" + File.separator, "g"), "/");
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
    protected var _conf :FlumpConf = new FlumpConf();
    protected var _confFile :File;
    protected const _settings :SharedObject = SharedObject.getLocal("flump/Exporter");

    private static const log :Log = Log.getLog(Exporter);
}
}

import flash.events.EventDispatcher;

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
