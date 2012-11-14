//
// Flump - Copyright 2012 Three Rings Design

package flump.test {

import flash.filesystem.File;

import flump.export.ExportConf;
import flump.export.Format;
import flump.export.JSONFormat;
import flump.export.Publisher;
import flump.export.ProjectConf;
import flump.export.StarlingFormat;
import flump.export.XMLFormat;
import flump.xfl.XflLibrary;

public class PublishTest
{
    public function PublishTest (runner :TestRunner, lib :XflLibrary) {
        _lib = lib;
        runner.run("Publish XML", makePublishTest("xml", XMLFormat));
        runner.run("Publish JSON", makePublishTest("json", JSONFormat));
        runner.run("Publish Starling", makePublishTest("starling", StarlingFormat,
            function (output :File) :void {  new StarlingResourcesTest(runner, output); }));
    }

    protected function makePublishTest (type :String, formatClass :Class, postPublish :Function=null) :Function {
        return function () :void {
            const exportDir :File = TestRunner.dist.resolvePath("test/publish" + type);
            if (exportDir.exists) exportDir.deleteDirectory(/*deleteDirectoryContents=*/true);
            exportDir.createDirectory();
            const conf :ExportConf = new ExportConf();
            conf.directory = "starling";
            conf.format = formatClass;
            const project :ProjectConf = new ProjectConf();
            project.exports = [conf];
            const pub :Publisher = new Publisher(exportDir, project);
            assert(pub.modified(_lib), "Lack of output should indicate modified");
            pub.publish(_lib);
            assert(!pub.modified(_lib), "Shouldn't be modified after publishing");
            if (postPublish != null) postPublish(conf.create(exportDir, _lib).outputFile);
        }
    }

    protected var _lib :XflLibrary;
}
}
