//
// Flump - Copyright 2013 Flump Authors

package flump.mold {

/** @private */
public function require (o :Object, field :String) :* {
    const result :* = o[field];
    if (result === undefined) throw new Error("Required field '" + field + "' not present in " + JSON.stringify(o));
    return result;
}
}
