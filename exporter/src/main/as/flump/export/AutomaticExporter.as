package flump.export {

import aspire.util.F;

import flash.events.ErrorEvent;
import flash.events.UncaughtErrorEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.setTimeout;

import flump.executor.Executor;
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
public class AutomaticExporter extends ExportController
{
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
        println("Exporting project: " + _confFile.nativePath);
        println();

        if (readProjectConfig()) {
            var exec :Executor = new Executor();
            exec.completed.connect(function () :void {
                // if finding docs generates a crit error, we need to fail immediately
                if (_handedCritError) exit();
            });
            findFlashDocuments(_importDirectory, exec, true);
        }
        else exit();
    }

    public function get complete () :BoolView { return _complete; }

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
        var exportDir :File = _confFile.parent.resolvePath(_conf.exportDir);
        println("Publishing to " + exportDir.nativePath + "...");
        if (exportDir.exists && !exportDir.isDirectory) {
            exit("Configured export directory exists as a file!");
            return;
        }
        if (!exportDir.exists) exportDir.createDirectory();

        var publisher :Publisher = new Publisher(exportDir, _conf, projectName);
        // wait a frame for the output to flush before starting the (long frame) publish
        setTimeout(F.bind(publish, publisher), 0);
    }

    protected function publish (publisher :Publisher) :void {
        var hasCombined :Boolean = false;
        var hasSingle :Boolean = false;
        for each (var config :ExportConf in _conf.exports) {
            hasCombined ||= config.combine;
            hasSingle ||= !config.combine;
            if (hasCombined && hasSingle) break;
        }
        try {
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

    override protected function handleParseError (err :ParseError) :void {
        if (err.severity == ParseError.CRIT) _handedCritError = true;
        printErr(err);
    }

    override protected function addDoc (status :DocStatus) :void {
        _statuses[_statuses.length] = status;
        println("Loading document: " + status.path + "...");
    }

    override protected function getDocs () :Array {
        return _statuses;
    }

    override protected function docLoadSucceeded (doc :DocStatus, lib :XflLibrary) :void {
        super.docLoadSucceeded(doc, lib);
        println("Load completed: " + doc.path + "...");
        checkValid();
    }

    override protected function docLoadFailed (file :File, doc :DocStatus, err :*) :void {
        super.docLoadFailed(file, doc, err);
        // this is a serious failure - simple parse errors are handled separately
        exit(err);
    }

    protected function printErr (err :*) :void {
        if (err is ParseError) {
            var pe :ParseError = ParseError(err);
            println("[" + pe.severity + "] @ " + pe.location + ": " + pe.message);
        } else if (err is Error) {
            println(Error(err).getStackTrace())
        } else if (err is ErrorEvent) {
            println("ErrorEvent: " + ErrorEvent(err).toString());
            if (err is UncaughtErrorEvent) {
                println(UncaughtErrorEvent(err).error.getStackTrace());
            }
        } else {
            println("" + err);
        }
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

    protected var _handedCritError :Boolean = false;
    protected var _statuses :Array = [];
}
}
