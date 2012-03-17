//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.utils.ByteArray;

public function bytesToXML (bytes :ByteArray) :XML {
   return new XML(bytes.readUTFBytes(bytes.length));
}
}
