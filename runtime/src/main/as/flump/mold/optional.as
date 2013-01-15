//
// Flump - Copyright 2013 Flump Authors

package flump.mold {

/** @private */
public function optional (o :Object, field :String, defaultValue :*) :* {
    const result :* = o[field];
    return (result !== undefined ? result : defaultValue);
}
}
