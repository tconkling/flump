//
// Executor - Copyright 2012 Three Rings Design

package flump.executor {

public class Finisher
{
    public function Finisher (onSucceed :Function, onFailure :Function) {
        _onSucceed = onSucceed;
        _onFailure = onFailure;
    }

    public function succeed (...result) :void {
        // Sigh, where's your explode operator, ActionScript?
        if (result.length == 0) _onSucceed();
        else _onSucceed(result[0]);
    }

    public function fail (result :*) :void { _onFailure(result); }

    protected var _onSucceed :Function;
    protected var _onFailure :Function;
}
}
