//
// Flump - Copyright 2013 Flump Authors

package flump.executor {

/**
 * A Future that provides interfaces to succeed or fail directly, or based
 * on the result of Function call.
 */
public class FutureTask extends Future
{
    public function FutureTask (onCompletion :Function=null) {
        super(onCompletion);
    }

    /** Succeed immediately */
    public function succeed (...result) :void {
        // Sigh, where's your explode operator, ActionScript?
        if (result.length == 0) super.onSuccess();
        else super.onSuccess(result[0]);
    }

    /** Fail immediately */
    public function fail (error :Object) :void { super.onFailure(error); }

    /**
     * Calls a function. Succeed if the function exits normally; fail with any
     * error thrown by the Function.
     */
    public function succeedAfter(f :Function, ...args) :void {
        applyMonitored(f, args);
        if (!isComplete) succeed();
    }

    /**
     * Call a function. Fail with any error thrown by the function, otherwise
     * no state change.
     */
    public function monitor (f :Function, ...args) :void { applyMonitored(f, args); }

    /** Returns a callback Function that behaves like #monitor */
    public function monitoredCallback (callback :Function, activeCallback :Boolean=true) :Function {
        return function (...args) :void {
            if (activeCallback && isComplete) return;
            applyMonitored(callback, args);
        };
    }

    protected function applyMonitored(monitored :Function, args :Array) :void {
        try {
            monitored.apply(this, args);
        } catch (e :Error) { fail(e); }
    }
}
}
