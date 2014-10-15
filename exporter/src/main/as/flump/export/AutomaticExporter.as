package flump.export {

import aspire.util.StringUtil;

import flash.events.ErrorEvent;
import flash.events.UncaughtErrorEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;

import flump.executor.Executor;
import flump.executor.Future;
import flump.xfl.ParseError;
import flump.xfl.XflLibrary;

import react.BoolValue;
import react.BoolView;

/**
 * This class expects to be run from the command-line script found at rsrc/flump-export. It sends
 * output to File.applicationDirectory.nativePath + "/exporter.log" rather than spawning any
 * UI windows for user interaction, and acts as though the user pressed the export all button, then
 * shuts down.
 */
public class AutomaticExporter {
    public function AutomaticExporter (project :File) {
        _complete.connect(function (complete :Boolean) :void {
            if (!complete) return;
            if (OUT != null) {
                OUT.close();
                OUT = null;
            }
        });

        FlumpApp.app.loaderInfo.uncaughtErrorEvents
            .addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, exit);

        var outFile :File = new File(File.applicationDirectory.nativePath + "/exporter.log");
        OUT = new FileStream();
        OUT.open(outFile, FileMode.WRITE);

        _confFile = project;
        exportProject();
    }

    public function get complete () :BoolView { return _complete; }

    public function get projectName () :String {
        return (_confFile != null ? _confFile.name.replace(/\.flump$/i, "") : "Untitled Project");
    }

    protected function exportProject () :void {
        println("Exporting project: " + _confFile.nativePath);
        println();

        try {
            _conf = ProjectConf.fromJSON(JSONFormat.readJSON(_confFile));
            _importDirectory = new File(_confFile.parent.resolvePath(_conf.importDir).nativePath);
            if (!_importDirectory.exists || !_importDirectory.isDirectory) {
                exit(new ParseError(_confFile.nativePath, ParseError.CRIT,
                    "Import directory doesn't exist (" + _importDirectory.nativePath + ")"));
                return;
            }
        } catch (e :Error) {
            exit(new ParseError(_confFile.nativePath, ParseError.CRIT,
                "Unable to read configuration"));
            return;
        }

        findFlashDocuments(_importDirectory, new Executor(), true);
    }

    protected function findFlashDocuments (base :File, exec :Executor,
            ignoreXflAtBase :Boolean = false) :void {
        Files.list(base, exec).succeeded.connect(function (files :Array) :void {
            for each (var file :File in files) {
                if (Files.hasExtension(file, "xfl")) {
                    if (ignoreXflAtBase) {
                        exit(new ParseError(base.nativePath,
                            ParseError.CRIT, "The import directory can't be an XFL directory, " +
                            "did you mean " + base.parent.nativePath + "?"));
                        return;
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
            println("Loading XFL: " + name + "...");
            break;
        case "fla":
            name = name.substr(0, name.lastIndexOf("."));
            load = new FlaLoader().load(name, file);
            println("Loading FLA: " + name + "...");
            break;
        default:
            // Unsupported file type, ignore
            return;
        }

        const status :DocStatus = new DocStatus(name, Ternary.UNKNOWN, Ternary.UNKNOWN, null);
        _statuses[_statuses.length] = status;
        load.succeeded.connect(function (lib :XflLibrary) :void {
            println("Load completed: " + name + "...");
            status.lib = lib;
            for each (var err :ParseError in lib.getErrors()) printErr(err);
            status.updateValid(Ternary.of(lib.valid));
            checkValid();
        });
        // any failed load means we can't finish the export
        load.failed.connect(exit);
    }

    /** returns all libs if all known flash docs are done loading, else null */
    protected function getLibs () :Vector.<XflLibrary> {
        var libs :Vector.<XflLibrary> = new <XflLibrary>[];
        for each (var status :DocStatus in _statuses) {
            if (status.lib == null) return null; // not done loading yet
            libs[libs.length] = status.lib;
        }
        return libs;
    }

    protected function checkValid () :void {
        if (getLibs() == null) return; // not done loading yet

        var valid :Boolean = _statuses.every(function (status :DocStatus, ..._) :Boolean {
            return status.isValid;
        });
        if (!valid) {
            // we've already printed our parse errors
            exit();
            return;
        }

        println("\nLoading complete...");

        if (_conf.exportDir == null) {
            exit("No export directory specified.");
            return;
        }

        if (_conf.exportDir == null) {
            exit("No export directory specified.");
            return;
        }

        var hasCombined :Boolean = false;
        var hasSingle :Boolean = false;
        for each (var config :ExportConf in _conf.exports) {
            hasCombined ||= config.combine;
            hasSingle ||= !config.combine;
            if (hasCombined && hasSingle) break;
        }
        try {
            var publisher :Publisher = new Publisher(new File(_conf.exportDir), _conf, projectName);
            // if we have one or more combined export format, publish them
            if (hasCombined) {
                println("Exporting combined formats...");
                var numPublished :int = publisher.publishCombined(getLibs());
                if (numPublished == 0) {
                    printErr("No suitable formats were found for combined publishing");
                } else {
                    println("" + numPublished + " combined formats published...");
                }
            }

            // now publish any appropriate single formats
            if (hasSingle) {
                for each (var status :DocStatus in _statuses) {
                    println("Exporting document " + status.path + "...");
                    numPublished = publisher.publishSingle(status.lib);
                    if (numPublished == 0) {
                        printErr("No suitable formats were found for single publishing");
                    } else {
                        println("" + numPublished + " formats published...");
                    }
                }
            }
        } catch (e :Error) {
            exit(e);
            return;
        }

        println("\nPublishing complete...");
        exit();
    }

    protected function printErr (err :*) :void {
        if (err is ParseError) {
            var pe :ParseError = ParseError(err);
            println("[" + pe.severity + "] @ " + pe.location + ": " + pe.message);
        } else if (err is Error)  {
            println("Error: " + Error(err).message);
            println(Error(err).getStackTrace())
        } else if (err is ErrorEvent) {
            println("ErrorEvent: " + ErrorEvent(err).toString());
            println(UncaughtErrorEvent(err).error.getStackTrace());
        } else println("" + err);
    }

    protected function print (message :String) :void {
        OUT.writeUTFBytes(message);
    }

    protected function println (message :String = "") :void {
        print(message + "\n");
    }

    protected function exit (err :* = null) :void {
        if (err != null) printErr(err);
        _complete.value = true;
    }

    protected const _complete :BoolValue = new BoolValue(false);

    protected var OUT :FileStream;

    protected var _confFile :File;
    protected var _conf :ProjectConf;
    protected var _importDirectory :File;
    protected var _statuses :Array = [];
}
}
