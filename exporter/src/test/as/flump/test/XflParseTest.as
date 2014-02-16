//
// Flump - Copyright 2013 Flump Authors

package flump.test {

import flump.executor.Future;
import flump.executor.FutureTask;
import flump.export.FlaLoader;
import flump.export.XflLoader;
import flump.xfl.XflLibrary;

public class XflParseTest
{
    public function XflParseTest (runner :TestRunner) {
        runner.runAsync("Parse Bella", makeParseTest("bella.fla", FlaLoader, function (lib :XflLibrary) :void {
            assert(lib.getErrors().length != 0, "Expected warnings in bella");
        }));
        runner.runAsync("Parse Squaredance", makeParseTest("squaredance", XflLoader, function (lib :XflLibrary) :void {
            assert(lib.getErrors().length == 0, "Expected no errors in squaredance");
            new PublishTest(runner, lib);
        }));
    }

    protected function makeParseTest (name :String, loaderClass :Class, postParse :Function) :Function {
        return function (finisher :FutureTask) :void {
            const load :Future = new loaderClass().load(name, TestRunner.resources.resolvePath(name));
            load.succeeded.connect(function (lib :XflLibrary) :void {
                finisher.succeedAfter(function (..._) :void {
                    assert(lib.valid, "Lib should be valid");
                    postParse(lib);
                });
            });
            load.failed.connect(finisher.fail);
         }
    }
}
}
