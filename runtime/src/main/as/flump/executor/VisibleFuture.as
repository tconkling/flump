//
// Executor - Copyright 2012 Three Rings Design

package flump.executor {

public class VisibleFuture extends Future
{
    public function succeed (...result) :void {
        // Sigh, where's your explode operator, ActionScript?
        if (result.length == 0) super.onSuccess();
        else super.onSuccess(result[0]);
    }
    public function fail (error :Object) :void { super.onFailure(error); }
}
}
