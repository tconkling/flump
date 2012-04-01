//
// Flump - Copyright 2012 Three Rings Design

package flump.test {

import flump.display.Movie;
import flump.display.StarlingResources;
import flump.executor.Finisher;

import com.threerings.util.DelayUtil;
import com.threerings.util.F;

public class RuntimePlaybackTest
{
    public static function addTests (runner :TestRunner, res :StarlingResources) :void {
        runner.runAsync("Play when added", new RuntimePlaybackTest(runner, res).playWhenAdded);
        //runner.runAsync("Play once", new RuntimePlaybackTest(runner, res).playOnce);
    }

    public function RuntimePlaybackTest (runner :TestRunner, res :StarlingResources) {
        _runner = runner;
        _res = res;
    }

    protected function setup (finisher :Finisher) :void {
        _finisher = finisher;
        _movie = _res.loadMovie("nesteddance");
        assert(_movie.frame == 0, "Frame starts at 0");
        assert(_movie.isPlaying, "Movie starts out playing");
        _runner.addChild(_movie);
        _movie.labelPassed.add(_labelsPassed.push);
    }

    public function playWhenAdded (finisher :Finisher) :void {
        setup(finisher);
        DelayUtil.delayFrames(2, finisher.monitor, [checkAdvanced]);
    }

    public function checkAdvanced () :void {
        assert(_movie.frame > 0, "Frame advances with time");
        DelayUtil.delayFrames(90, _finisher.monitor, [checkAllLabelsFired]);
    }

    public function checkAllLabelsFired () :void {
        _runner.removeChild(_movie);
        passedAllLabels();
        _labelsPassed.splice(0, _labelsPassed.length);
        _finisher.succeed();
    }

    /*public function playOnce (finisher :Finisher) :void {
        setup(finisher);
        _movie.playOnce();
        DelayUtil.delayFrames(120, _finisher.monitor, [checkPlayOnce]);
    }

    public function checkPlayOnce () :void {
        passedAllLabels();
        assert(_labelsPassed.length == 4, "Only pass the labels once");
        assert(_movie.frame == _movie.frames - 1, "Play once stops at last frame");
        _finisher.succeed();
    }*/

    public function passedAllLabels () :void {
        passed("timepassed");
        passed("moretimepassed");
        passed(Movie.LAST_FRAME);
        passed(Movie.FIRST_FRAME);
    }

    protected function passed (label :String) :void {
        assert(_labelsPassed.indexOf(label) != -1, "Should've passed " + label);
    }

    protected var _finisher :Finisher;
    protected var _movie :Movie;
    protected var _runner :TestRunner;
    protected var _res :StarlingResources;

    protected const _labelsPassed :Vector.<String> = new Vector.<String>();
}
}
