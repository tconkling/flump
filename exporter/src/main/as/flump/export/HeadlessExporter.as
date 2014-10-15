package flump.export {

import flash.events.ErrorEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;

import react.BoolValue;
import react.BoolView;

public class HeadlessExporter {
    public function HeadlessExporter (project :File) {
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
