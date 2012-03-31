//
// Flump - Copyright 2012 Three Rings Design

package flump.test {

    public function assert (condition :Boolean, failureMessage :String="") :void {
        if (!condition) {
            throw new Error(failureMessage);
        }
    }
}
