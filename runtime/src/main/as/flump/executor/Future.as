//
// Flump - Copyright 2013 Flump Authors

package flump.executor {

import org.osflash.signals.Signal;

/**
 * The result of a pending or completed asynchronous task.
 */
public class Future
{
    /** @private */
    public function Future (onCompleted :Function=null) {
        _onCompleted = onCompleted;
    }

    /** Dispatches the result if the future completes successfully. */
    public function get succeeded () :Signal {
        return _onSuccess || (_onSuccess = new Signal(Object));
    }

    /** Dispatches the result if the future fails. */
    public function get failed () :Signal {
        return _onFailure || (_onFailure = new Signal(Object));
    }

    /** Dispatches if the future is cancelled. */
    public function get cancelled () :Signal {
        return _onCancel || (_onCancel = new Signal());
    }

    /** Dispatches the Future when it succeeds, fails, or is cancelled. */
    public function get completed () :Signal {
        return _onCompletion || (_onCompletion = new Signal(Future));
    }

    /** Returns true if the Future completed successfully. */
    public function get isSuccessful () :Boolean { return _state == STATE_SUCCEEDED; }
    /** Returns true if the Future failed. */
    public function get isFailure () :Boolean { return _state == STATE_FAILED; }
    /** Returns true if the future was cancelled. */
    public function get isCancelled () :Boolean { return _state == STATE_CANCELLED; }
    /** Returns true if the future has succeeded or failed or was cancelled. */
    public function get isComplete () :Boolean { return _state != STATE_DEFAULT; }

    /**
     * Returns the result of the success or failure. If the success didn't call through with an
     * object or the future was cancelled, returns undefined.
     */
    public function get result () :* { return _result; }

    internal function onSuccess (...result) :void {
        if (result.length > 0) _result = result[0];
        _state = STATE_SUCCEEDED;
        if (_onSuccess) _onSuccess.dispatch(_result);
        dispatchCompletion();
    }

    internal function onFailure (error :Object) :void {
        _result = error;
        _state = STATE_FAILED;
        if (_onFailure) _onFailure.dispatch(error);
        dispatchCompletion();
    }

    internal function onCancel () :void {
        _state = STATE_CANCELLED;
        if (_onCancel) _onCancel.dispatch();
        _onCompleted = null;// Don't tell the Executor we completed as we're not running
        dispatchCompletion();
    }

    protected function dispatchCompletion () :void {
        if (_onCompletion) _onCompletion.dispatch(this);
        if (_onCompleted != null) _onCompleted(this);
        _onCompleted = null;// Allow Executor to be GC'd if the Future is hanging around
    }

    protected var _state :int = 0;
    protected var _result :* = undefined;

    // All Future signals are created lazily
    protected var _onSuccess :Signal;
    protected var _onFailure :Signal;
    protected var _onCancel :Signal;
    protected var _onCompletion :Signal;
    protected var _onCompleted :Function;

    protected static const STATE_DEFAULT :int = 0;
    protected static const STATE_FAILED :int = 1;
    protected static const STATE_SUCCEEDED :int = 2;
    protected static const STATE_CANCELLED :int = 3;
}
}
