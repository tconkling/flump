package flump.export {

import flash.events.ErrorEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;

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


        var outFile :File = new File(File.applicationDirectory.nativePath + "/exporter.log");
        OUT = new FileStream();
        OUT.open(outFile, FileMode.WRITE);

        exportProject(project);
    }

    public function get complete () :BoolView { return _complete; }

    protected function exportProject (project :File) :void {
        println("Exporting project: " + project.nativePath);
        println();
        _complete.value = true;
    }

    protected function printErr (err :*) :void {
        if (err is Error) println(Error(err).message);
        else if (err is ErrorEvent) println(ErrorEvent(err).text);
        else println("" + err);
    }

    protected function print (message :String) :void {
        OUT.writeUTFBytes(message);
    }

    protected function println (message :String = "") :void {
        print(message + "\n");
    }

    protected const _complete :BoolValue = new BoolValue(false);

    protected var OUT :FileStream;
}
}
