//
// Flump - Copyright 2012 Three Rings Design

package flump.test {

import flump.executor.Finisher;
import flump.executor.Future;
import flump.export.XflLoader;
import flump.xfl.XflLibrary;

public class XflParseTest
{
    public function XflParseTest (runner :TestRunner) {
        _runner = runner;
        runner.run("Parse Bella", parseBella);
        runner.run("Parse Squaredance", parseSquare);
    }

    protected function parseBella (finisher :Finisher) :void {
        parse("bella", onBellaSuccess, finisher);
    }

    protected function onBellaSuccess (lib :XflLibrary, finisher :Finisher) :void {
        finisher.succeed();
    }

    protected function parseSquare (finisher :Finisher) :void {
        parse("squaredance", onSquareSuccess, finisher);
    }

    protected function onSquareSuccess (lib :XflLibrary, finisher :Finisher) :void {
        finisher.succeed();
    }

    public function parse (name :String, onSuccess :Function, finisher :Finisher) :void {
       const load :Future = new XflLoader().load(name, TestRunner.resources.resolvePath(name));
       load.succeeded.add(function (lib :XflLibrary) :void { onSuccess(lib, finisher);  });
       load.failed.add(finisher.fail);
    }

    protected var _runner :TestRunner;
}
}
