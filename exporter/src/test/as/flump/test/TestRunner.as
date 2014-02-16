//
// Flump - Copyright 2013 Flump Authors

package flump.test {

import aspire.util.Log;
import aspire.util.Map;
import aspire.util.Maps;

import flash.desktop.NativeApplication;
import flash.filesystem.File;

import flump.display.MoviePlayer;

import flump.executor.Executor;
import flump.executor.Future;
import flump.executor.FutureTask;

import starling.core.Starling;

import starling.display.Sprite;

public class TestRunner extends Sprite
{
    public static const root :File = new File(File.applicationDirectory.nativePath);
    public static const resources :File = root.resolvePath('../src/test/resources');
    public static const dist :File = root.resolvePath('../dist');

    public function TestRunner () {
        Log.setLevel("", Log.INFO);
        // create a MoviePlayer
        Starling.current.juggler.add(new MoviePlayer(this));

        _exec.completed.connect(onCompletion);
        _exec.terminated.connect(function (..._) :void {
            if (_passed.length > 0) {
                trace("Passed:");
                for each (var name :String in _passed) trace("  " + name);
            }
            if (_failed.length > 0) {
                trace("Failed:");
                for each (name in _failed) trace("  " + name);
            }
            NativeApplication.nativeApplication.exit(_failed.length == 0 ? 0 : 1);
        });
        new XflParseTest(this);
    }

    public function run (name :String, f :Function) :void {
        runAsync(name, function (future :FutureTask) :void { future.succeedAfter(f); });
    }

    public function runAsync (name :String, f :Function) :void { _runs.put(_exec.submit(f), name); }

    protected function onCompletion (f :Future) :void {
        const name :String = _runs.remove(f);
        if (name == null) {
            log.error("Unknown test completed", "future", f, "result", f.result);
            return;
        }
        if (f.isSuccessful) {
            log.info("Passed", "test", name);
            _passed.push(name);
        } else {
            _failed.push(name);
            if (f.result is Error) log.error("Failed", "test", name, f.result);
            else log.error("Failed", "test", name, "reason", f.result);
            _exec.shutdownNow();
        }
        if (_exec.isIdle) _exec.shutdown();
    }

    protected const _exec :Executor = new Executor();
    protected const _runs :Map = Maps.newMapOf(Future);//String name

    protected const _passed :Vector.<String> = new <String>[];
    protected const _failed :Vector.<String> = new <String>[];

    private static const log :Log = Log.getLog(TestRunner);
}
}
