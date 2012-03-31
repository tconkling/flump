//
// Flump - Copyright 2012 Three Rings Design

package flump.test {

import flash.filesystem.File;

import flump.export.DeviceType;
import flump.export.Format;
import flump.export.JSONFormat;
import flump.export.Publisher;
import flump.export.StarlingFormat;
import flump.export.XMLFormat;
import flump.xfl.XflLibrary;

public class PublishTest
{
    public function PublishTest (runner :TestRunner, lib :XflLibrary) {
        _lib = lib;
        runner.run("Publish XML", makePublishTest("xml", new XMLFormat()));
        runner.run("Publish JSON", makePublishTest("json", new JSONFormat()));
        runner.run("Publish Starling", makePublishTest("starling", new StarlingFormat()));
    }

    protected function makePublishTest (type :String, format :Format) :Function {
        return function () :void {
            const exportDir :File = TestRunner.dist.resolvePath("test/publish" + type);
            if (exportDir.exists) exportDir.deleteDirectory(/*deleteDirectoryContents=*/true);
            exportDir.createDirectory();
            const pub :Publisher = new Publisher(exportDir, format);
            assert(pub.modified(_lib), "Lack of output should indicate modified");
            pub.publish(_lib, DeviceType.IPHONE);
            assert(exportDir.resolvePath(_lib.location + "/" + format.metaFilename).exists,
                "Output wasn't created");
            assert(!pub.modified(_lib), "Shouldn't be modified after publishing");
        }
    }

    protected var _lib :XflLibrary;
}
}
