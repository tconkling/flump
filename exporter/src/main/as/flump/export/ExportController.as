package flump.export {

import aspire.util.F;
import aspire.util.Joiner;
import aspire.util.Log;
import aspire.util.StringUtil;

import flash.filesystem.File;

import flump.executor.Executor;
import flump.executor.Future;
import flump.xfl.ParseError;
import flump.xfl.XflLibrary;

public class ExportController {
    public function get projectName () :String {
        return (_confFile != null ? _confFile.name.replace(/\.flump$/i, "") : "Untitled Project");
    }

    protected function handleParseError (err :ParseError) :void {
        throw new Error("abstract");
    }

    protected function addDocStatus (status :DocStatus) :void {
        throw new Error("abstract");
    }

    protected function getDocStatuses () :Array {
        throw new Error("abstract");
    }

    protected function readProjectConfig () :Boolean {
        if (_confFile == null) return false;

        try {
            var projJson :Object = JSONFormat.readJSON(_confFile);
            var fileVersion :* = projJson["fileVersion"];
            _conf = ProjectConf.fromJSON(projJson);
            if (fileVersion != _conf.fileVersion) setProjectDirty(true);
            _importDirectory = new File(_confFile.parent.resolvePath(_conf.importDir).nativePath);
            if (!_importDirectory.exists || !_importDirectory.isDirectory) {
                handleParseError(new ParseError(_confFile.nativePath, ParseError.CRIT,
                    "Import directory doesn't exist (" + _importDirectory.nativePath + ")"));
                return false;
            }
        } catch (e :Error) {
            if (e is ParseError) handleParseError(ParseError(e));
            handleParseError(new ParseError(_confFile.nativePath, ParseError.CRIT,
                "Unable to read configuration"));
            return false;
        }

        return true;
    }

    protected function setProjectDirty (val :Boolean) :void {
        _projectDirty = val;
    }

    protected function findFlashDocuments (base :File, exec :Executor,
            ignoreXflAtBase :Boolean = false) :void {
        Files.list(base, exec).succeeded.connect(function (files :Array) :void {
            if (exec.isShutdown) return;
            for each (var file :File in files) {
                if (Files.hasExtension(file, "xfl")) {
                    if (ignoreXflAtBase) {
                        handleParseError(new ParseError(base.nativePath,
                            ParseError.CRIT, "The import directory can't be an XFL directory, " +
                                "did you mean " + base.parent.nativePath + "?"));
                    } else addFlashDocument(file);
                    return;
                }
            }
            for each (file in files) {
                if (StringUtil.startsWith(file.name, ".", "RECOVER_")) {
                    // Ignore hidden VCS directories, and recovered backups created by Flash
                    continue;
                }
                if (file.isDirectory) findFlashDocuments(file, exec);
                else addFlashDocument(file);
            }
        });
    }

    protected function addFlashDocument (file :File) :void {
        var importPathLen :int = _importDirectory.nativePath.length + 1;
        var name :String = file.nativePath.substring(importPathLen).replace(
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

        const status :DocStatus = new DocStatus(name, Ternary.UNKNOWN, Ternary.UNKNOWN, null);
        addDocStatus(status);
        load.succeeded.connect(F.argify(F.bind(docLoadSucceeded, status, F._1), 1));
        load.failed.connect(F.argify(F.bind(docLoadFailed, file, status, F._1), 1));
    }

    protected function docLoadSucceeded (doc :DocStatus, lib :XflLibrary) :void {
        var err :ParseError;

        doc.lib = lib;

        for each (err in lib.getErrors()) handleParseError(err);
        doc.updateValid(Ternary.of(lib.valid));

        // validate our exportConfs when all docs have loaded
        if (this.allDocsLoaded && this.hasCombinedExportConfig()) {
            var docStatuses :Array = getDocStatuses();
            if (docStatuses.length > 0) {
                var frameRate :Number = DocStatus(docStatuses[0]).lib.frameRate;
                for each (var docStatus :DocStatus in docStatuses) {
                    if (docStatus.lib.frameRate != frameRate) {
                        err = docStatus.lib.addTopLevelError(ParseError.CRIT, Joiner.pairs(
                            "Invalid framerate (all XflLibraries within a combined publish must use the same framerate)",
                            "framerate", docStatus.lib.frameRate,
                            "expectedFramerate", frameRate));
                        handleParseError(err);
                        docStatus.updateValid(Ternary.of(docStatus.lib.valid));
                    }
                }
            }
        }
    }

    protected function docLoadFailed (file :File, doc :DocStatus, err :*) :void {
        doc.updateValid(Ternary.FALSE);
    }

    /** returns all libs if all known flash docs are done loading, else null */
    protected function getLibs () :Vector.<XflLibrary> {
        if (!this.allDocsLoaded) {
            return null;
        }

        var libs :Vector.<XflLibrary> = new <XflLibrary>[];
        for each (var status :DocStatus in getDocStatuses()) {
            libs[libs.length] = status.lib;
        }
        return libs;
    }

    protected function get allDocsLoaded () :Boolean {
        for each (var status :DocStatus in getDocStatuses()) {
            if (status.lib == null) return false; // not done loading yet
        }
        return true;
    }

    protected function hasCombinedExportConfig () :Boolean {
        if (_conf == null) return false;
        for each (var config :ExportConf in _conf.exports) if (config.combine) return true;
        return false;
    }

    protected function hasSingleExportConfig () :Boolean {
        if (_conf == null) return false;
        for each (var config :ExportConf in _conf.exports) if (!config.combine) return true;
        return false;
    }

    protected var _confFile :File;
    protected var _conf :ProjectConf;
    protected var _importDirectory :File;

    protected var _projectDirty :Boolean; // true if project has unsaved changes

    protected static const log :Log = Log.getLog(ExportController);
}
}
