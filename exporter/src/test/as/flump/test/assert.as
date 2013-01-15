//
// Flump - Copyright 2013 Flump Authors

package flump.test {

    public function assert (condition :Boolean, failureMessage :String="") :void {
        if (!condition) {
            throw new Error(failureMessage);
        }
    }
}
