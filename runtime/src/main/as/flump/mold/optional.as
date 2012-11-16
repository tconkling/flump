//
// Flump - Copyright 2012 Three Rings Design

package flump.mold {

/** @private */
public function optional (o :Object, field :String, defaultValue :*) :* {
    const result :* = o[field];
    return (result !== undefined ? result : defaultValue);
}
}
