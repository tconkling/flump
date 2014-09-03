//
// Flump - Copyright 2013 Flump Authors

package flump.test {

import flash.filesystem.File;

import flump.export.ExportConf;
import flump.export.JSONFormat;
import flump.export.ProjectConf;
import flump.export.Publisher;
import flump.export.JSONZipFormat;
import flump.export.XMLFormat;
import flump.xfl.XflLibrary;

public class PublishTest
{
    public function PublishTest (runner :TestRunner, lib :XflLibrary) {
        _lib = lib;
        runner.run("Publish XML", makePublishTest("xml", XMLFormat));
        runner.run("Publish JSON", makePublishTest("json", JSONFormat));
        runner.run("Publish JSONZip", makePublishTest("jsonzip", JSONZipFormat,
            function (output :File) :void {  new StarlingResourcesTest(runner, output); }));
    }

    protected function makePublishTest (name :String, formatClass :Class, postPublish :Function=null) :Function {
        return function () :void {
            const exportDir :File = TestRunner.dist.resolvePath("test/publish" + name);
            if (exportDir.exists) exportDir.deleteDirectory(/*deleteDirectoryContents=*/true);
            exportDir.createDirectory();
            const conf :ExportConf = new ExportConf();
            conf.format = formatClass.NAME;
            const project :ProjectConf = new ProjectConf();
            project.exportDir = "starling";
            project.exports = [conf];
            const pub :Publisher = new Publisher(exportDir, project, "Test Project");
            assert(pub.modified(_lib), "Lack of output should indicate modified");
            pub.publish(_lib);
            assert(!pub.modified(_lib), "Shouldn't be modified after publishing");
            if (postPublish != null) {
                postPublish(conf.createPublishFormat(exportDir, _lib)["outputFile"]);
            }
        }
    }

    protected var _lib :XflLibrary;
}
}
