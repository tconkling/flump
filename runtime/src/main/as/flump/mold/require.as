//
// Flump - Copyright 2012 Three Rings Design

package flump.mold {

public function require (o :Object, field :String) :* {
    const result :* = o[field];
    if (result === undefined) throw new Error("Required field '" + field + "' not present in " + JSON.stringify(o));
    return result;
}
}
