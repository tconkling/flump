//
// Executor - Copyright 2012 Three Rings Design

package flump.executor {

public class VisibleFuture extends Future
{
    public function VisibleFuture (onCompletion :Function=null) {
        super(onCompletion);
    }

    public function succeed (...result) :void {
        // Sigh, where's your explode operator, ActionScript?
        if (result.length == 0) super.onSuccess();
        else super.onSuccess(result[0]);
    }

    public function fail (error :Object) :void { super.onFailure(error); }

    public function monitoredCallback (callback :Function, activeCallback :Boolean=true) :Function {
        return function (...args) :void {
            if (activeCallback && isComplete) return;
            applyMonitored(callback, args);
        };
    }

    public function monitor (f :Function, ...args) :void { applyMonitored(f, args); }

    public function succeedAfter(f :Function, ...args) :void {
        applyMonitored(f, args);
        if (!isComplete) succeed();
    }

    protected function applyMonitored(monitored :Function, args :Array) :void {
        try {
            monitored.apply(this, args);
        } catch (e :Error) { fail(e); }
    }

}
}
