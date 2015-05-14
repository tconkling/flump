//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import aspire.util.F;
import aspire.util.StringUtil;

import flash.desktop.NativeApplication;
import flash.display.NativeMenu;
import flash.display.NativeMenuItem;
import flash.display.Stage;
import flash.display.StageQuality;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filesystem.File;
import flash.utils.IDataOutput;

import flump.executor.Executor;
import flump.xfl.ParseError;
import flump.xfl.XflLibrary;

import mx.events.PropertyChangeEvent;
import mx.managers.PopUpManager;

import spark.components.DataGrid;
import spark.components.Window;
import spark.events.GridSelectionEvent;

public class ProjectController extends ExportController
{
    public static const NA :NativeApplication = NativeApplication.nativeApplication;

    public function ProjectController (configFile :File = null) {
        _win = new ProjectWindow();
        _win.open();
        _errorsGrid = _win.errors;
        _flashDocsGrid = _win.libraries;

        _confFile = configFile;
        if (_confFile == null) {
            _conf = new ProjectConf();
        } else {
            if (readProjectConfig()) {
                setImportDirectory(_importDirectory);
            } else {
                _importDirectory = null;
                _confFile = null;
                _conf = null;
            }
        }

        var curSelection :DocStatus = null;
        _flashDocsGrid.addEventListener(GridSelectionEvent.SELECTION_CHANGE, function (..._) :void {
            log.info("Changed", "selected", _flashDocsGrid.selectedIndices);
            onSelectedItemChanged();

            if (curSelection != null) {
                curSelection.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE,
                    onSelectedItemChanged);
            }
            var newSelection :DocStatus = _flashDocsGrid.selectedItem as DocStatus;
            if (newSelection != null) {
                newSelection.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE,
                    onSelectedItemChanged);
            }
            curSelection = newSelection;
        });

        // Reload
        _win.reload.addEventListener(MouseEvent.CLICK, F.bind(reloadNow));

        // Export
        _win.export.addEventListener(MouseEvent.CLICK, function (..._) :void {
            for each (var status :DocStatus in _flashDocsGrid.selectedItems) {
                exportFlashDocument(status);
            }
        });

        // Preview
        _win.preview.addEventListener(MouseEvent.CLICK, function (..._) :void {
            FlumpApp.app.showPreviewWindow(_conf, _flashDocsGrid.selectedItem.lib);
        });

        // Export All, Modified
        _win.exportAll.addEventListener(MouseEvent.CLICK, F.bind(exportAll, false));
        _win.exportModified.addEventListener(MouseEvent.CLICK, F.bind(exportAll, true));

        // Import/Export directories
        _importChooser = new DirChooser(null, _win.importRoot, _win.browseImport);
        _importChooser.changed.connect(setImportDirectory);
        _exportChooser = new DirChooser(null, _win.exportRoot, _win.browseExport);
        _exportChooser.changed.connect(F.bind(reloadNow));

        _importChooser.changed.connect(F.bind(setProjectDirty, true));
        _exportChooser.changed.connect(F.bind(setProjectDirty, true));

        // Edit Formats
        var editFormatsController :EditFormatsController = null;
        _win.editFormats.addEventListener(MouseEvent.CLICK, function (..._) :void {
            if (editFormatsController == null || editFormatsController.closed) {
                editFormatsController = new EditFormatsController(_conf);
                editFormatsController.formatsChanged.connect(updateUiFromConf);
                editFormatsController.formatsChanged.connect(F.bind(setProjectDirty, true));
            } else {
                editFormatsController.show();
            }
        });

        _win.addEventListener(Event.CLOSING, function (e :Event) :void {
            if (_projectDirty) {
                e.preventDefault();
                promptToSaveChanges();
            }
        });

        updateUiFromConf();
        updateWindowTitle();

        setupMenus();
    }

    public function get projectDirty () :Boolean {
        return _projectDirty;
    }

    public function save (onSuccess :Function = null) :void {
        if (_confFile == null) {
            saveAs(onSuccess);
        } else {
            saveConf(onSuccess);
        }
    }

    public function saveAs (onSuccess :Function = null) :void {
        var file :File = new File();
        file.addEventListener(Event.SELECT, function (..._) :void {
            // Ensure the filename ends with .flump
            if (!StringUtil.endsWith(file.name.toLowerCase(), ".flump")) {
                file = file.parent.resolvePath(file.name + ".flump");
            }

            _confFile = file;
            saveConf(onSuccess);
        });
        file.browseForSave("Save Flump Configuration");
    }

    public function get configFile () :File {
        return _confFile;
    }

    public function get win () :Window {
        return _win;
    }

    protected function exportAll (modifiedOnly :Boolean) :void {
        // if we have one or more combined export format, publish them
        if (hasCombinedExportConfig()) {
            var valid :Boolean = _flashDocsGrid.dataProvider.toArray()
                .every(function (status :DocStatus,..._) :Boolean { return status.isValid; });
            if (valid) exportCombined();
        }
        // now publish any appropriate single formats
        if (hasSingleExportConfig()) {
            for each (var status :DocStatus in _flashDocsGrid.dataProvider.toArray()) {
                if (status.isValid && (!modifiedOnly || status.isModified)) {
                    exportFlashDocument(status);
                }
            }
        }
    }

    protected function promptToSaveChanges () :void {
        var unsavedWindow :UnsavedChangesWindow = new UnsavedChangesWindow();
        unsavedWindow.x = (_win.width - unsavedWindow.width) * 0.5;
        unsavedWindow.y = (_win.height - unsavedWindow.height) * 0.5;
        PopUpManager.addPopUp(unsavedWindow, _win, true);

        unsavedWindow.closeButton.visible = false;
        unsavedWindow.prompt.text = "Save changes to '" + projectName + "'?";

        unsavedWindow.cancel.addEventListener(MouseEvent.CLICK, function (..._) :void {
            PopUpManager.removePopUp(unsavedWindow);
        });

        unsavedWindow.dontSave.addEventListener(MouseEvent.CLICK, function (..._) :void {
            PopUpManager.removePopUp(unsavedWindow);
            _projectDirty = false;
            _win.close();
        });

        unsavedWindow.save.addEventListener(MouseEvent.CLICK, function (..._) :void {
            PopUpManager.removePopUp(unsavedWindow);
            save(F.bind(_win.close));
        });
    }

    protected function setupMenus () :void {
        if (NativeApplication.supportsMenu) {
            // If we're on a Mac, the menus will be set up at the application level.
            return;
        }

        _win.nativeWindow.menu = new NativeMenu();

        var fileMenuItem  :NativeMenuItem =
            _win.nativeWindow.menu.addSubmenu(new NativeMenu(), "File");

        // Add save and save as by index to work with the existing items on Mac
        // Mac menus have an existing "Close" item, so everything we add should go ahead of that
        var newMenuItem :NativeMenuItem = fileMenuItem.submenu.addItemAt(new NativeMenuItem("New Project"), 0);
        newMenuItem.keyEquivalent = "n";
        newMenuItem.addEventListener(Event.SELECT, function (..._) :void {
            FlumpApp.app.newProject();
        });

        var openMenuItem :NativeMenuItem =
            fileMenuItem.submenu.addItemAt(new NativeMenuItem("Open Project..."), 1);
        openMenuItem.keyEquivalent = "o";
        openMenuItem.addEventListener(Event.SELECT, function (..._) :void {
            FlumpApp.app.showOpenProjectDialog();
        });
        fileMenuItem.submenu.addItemAt(new NativeMenuItem("Sep", /*separator=*/true), 2);

        const saveMenuItem :NativeMenuItem =
            fileMenuItem.submenu.addItemAt(new NativeMenuItem("Save Project"), 3);
        saveMenuItem.keyEquivalent = "s";
        saveMenuItem.addEventListener(Event.SELECT, F.bind(save));

        const saveAsMenuItem :NativeMenuItem =
            fileMenuItem.submenu.addItemAt(new NativeMenuItem("Save Project As..."), 4);
        saveAsMenuItem.keyEquivalent = "S";
        saveAsMenuItem.addEventListener(Event.SELECT, F.bind(saveAs));
    }

    protected function updateWindowTitle () :void {
        var name :String = this.projectName;
        if (_projectDirty) name += "*";
        _win.title = name;
    }

    protected function saveConf (onSuccess :Function) :void {
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

            setProjectDirty(false);
            updateWindowTitle();

            if (onSuccess != null) {
                onSuccess();
            }
        });
    }

    protected function reloadNow () :void {
        setImportDirectory(_importChooser.dir);
        onSelectedItemChanged();
    }

    protected function updateUiFromConf (..._) :void {
        if (_confFile != null) {
            _importChooser.dir = (_conf.importDir != null) ? _confFile.parent.resolvePath(_conf.importDir) : null;
            _exportChooser.dir = (_conf.exportDir != null) ? _confFile.parent.resolvePath(_conf.exportDir) : null;
        } else {
            _importChooser.dir = null;
            _exportChooser.dir = null;
        }

        var formatNames :Array = [];
        var hasCombined :Boolean = false;
        if (_conf != null) {
            for each (var exportConf :ExportConf in _conf.exports) {
                formatNames.push(exportConf.description);
                hasCombined ||= exportConf.combine;
            }
        }
        _win.formatOverview.text = formatNames.join(", ");
        _win.exportAll.label = hasCombined ? "Export Combined" : "Export All";
        checkValid();
        _win.exportModified.enabled = !hasCombined;
        _win.export.enabled = !hasCombined;

        updateWindowTitle();
    }

    protected function onSelectedItemChanged (..._) :void {
        _win.export.enabled = !hasCombinedExportConfig() && _exportChooser.dir != null &&
            _flashDocsGrid.selectionLength > 0 &&
            _flashDocsGrid.selectedItems.some(function (status :DocStatus, ..._) :Boolean {
                return status.isValid;
            });

        var status :DocStatus = _flashDocsGrid.selectedItem as DocStatus;
        _win.preview.enabled = status != null && status.isValid;

        _win.selectedItem.text = (status == null ? "" : status.path);
    }

    protected function createPublisher () :Publisher {
        if (_exportChooser.dir == null || _conf.exports.length == 0) return null;
        return new Publisher(_exportChooser.dir, _conf, projectName);
    }

    protected function setImportDirectory (dir :File) :void {
        _importDirectory = dir;
        _flashDocsGrid.dataProvider.removeAll();
        _errorsGrid.dataProvider.removeAll();
        if (dir == null) {
            return;

        }
        if (_docFinder != null) {
            _docFinder.shutdownNow();
        }
        _docFinder = new Executor();
        findFlashDocuments(dir, _docFinder, true);
        _win.reload.enabled = true;
    }

    protected function exportFlashDocument (status :DocStatus) :void {
        const stage :Stage = NA.activeWindow.stage;
        const prevQuality :String = stage.quality;

        stage.quality = StageQuality.BEST;

        try {
            if (_exportChooser.dir == null) {
                throw new Error("No export directory specified.");
            }
            if (_conf.exports.length == 0) {
                throw new Error("No export formats specified.");
            }
            var published :int = createPublisher().publishSingle(status.lib);
            if (published == 0) {
                throw new Error("No suitable formats were found for publishing");
            }
        } catch (e :Error) {
            log.warning("publishing failed", e);
            ErrorWindowMgr.showErrorPopup("Publishing Failed", e.message, _win);
        }

        stage.quality = prevQuality;
        status.updateModified(Ternary.FALSE);
    }

    protected function exportCombined () :void {
        const stage :Stage = NA.activeWindow.stage;
        const prevQuality :String = stage.quality;

        stage.quality = StageQuality.BEST;

        try {
            if (_exportChooser.dir == null) {
                throw new Error("No export directory specified.");
            }
            if (_conf.exports.length == 0) {
                throw new Error("No export formats specified.");
            }
            var published :int = createPublisher().publishCombined(getLibs());
            if (published == 0) {
                throw new Error("No suitable formats were found for publishing");
            }
        } catch (e :Error) {
            log.warning("publishing failed", e);
            ErrorWindowMgr.showErrorPopup("Publishing Failed", e.message, _win);
        }

        stage.quality = prevQuality;
        for each (var status :DocStatus in _flashDocsGrid.dataProvider) {
            status.updateModified(Ternary.FALSE);
        }
    }

    protected function checkModified () :void {
        var libs :Vector.<XflLibrary> = getLibs();
        if (libs == null) return; // not done loading yet

        // all the docs we know about have been loaded
        var pub :Publisher = createPublisher();
        for (var ii :int = 0; ii < libs.length; ii++) {
            var status :DocStatus = _flashDocsGrid.dataProvider[ii];
            status.updateModified(Ternary.of(pub == null || pub.modified(libs, ii)))
        }
    }

    protected function checkValid () :void {
        if (getLibs() == null) {
            _win.exportAll.enabled = false;
            return;
        }

        _win.exportAll.enabled = !hasCombinedExportConfig() || _flashDocsGrid.dataProvider.toArray()
            .every(function (status :DocStatus, ..._) :Boolean {
                return status.isValid;
            });
    }

    override protected function setProjectDirty (val :Boolean) :void {
        super.setProjectDirty(val);
        updateWindowTitle();
    }

    override protected function handleParseError (err :ParseError) :void {
        _errorsGrid.dataProvider.addItem(err);
    }

    override protected function docLoadSucceeded (doc :DocStatus, lib :XflLibrary) :void {
        super.docLoadSucceeded(doc, lib);
        checkModified();
        checkValid();
    }

    override protected function docLoadFailed (file :File, doc :DocStatus, err :*) :void {
        super.docLoadFailed(file, doc, err);
        trace("Failed to load " + file.nativePath + ": " + err);
        throw err;
    }

    override protected function addDocStatus (status :DocStatus) :void {
        _flashDocsGrid.dataProvider.addItem(status);
    }

    override protected function getDocStatuses () :Array {
        return _flashDocsGrid.dataProvider.toArray();
    }

    protected var _docFinder :Executor;
    protected var _win :ProjectWindow;
    protected var _flashDocsGrid :DataGrid;
    protected var _errorsGrid :DataGrid;
    protected var _exportChooser :DirChooser;
    protected var _importChooser :DirChooser;
}
}

