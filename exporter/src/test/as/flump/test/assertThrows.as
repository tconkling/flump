//
// Flump - Copyright 2013 Flump Authors

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
