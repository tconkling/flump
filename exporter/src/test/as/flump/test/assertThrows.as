//
// Flump - Copyright 2012 Three Rings Design

package flump.test {

    public function assertThrows (f :Function, failureMessage :String="") :void {
        try {
            f();
        } catch (e :Error) {
            return;
        }
        throw new Error(failureMessage);
    }
}
