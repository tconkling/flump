package flump.export {

import flash.events.EventDispatcher;

import flump.xfl.XflLibrary;

import mx.core.IPropertyChangeNotifier;
import mx.events.PropertyChangeEvent;

public class DocStatus extends EventDispatcher implements IPropertyChangeNotifier {
    public var path :String;
    public var modified :String;
    public var valid :String = PENDING;
    public var lib :XflLibrary;

    public function DocStatus (path :String, modified :Ternary, valid :Ternary, lib :XflLibrary) {
        this.lib = lib;
        this.path = path;
        _uid = path;

        updateModified(modified);
        updateValid(valid);
    }

    public function updateValid (newValid :Ternary) :void {
        changeField("valid", function (..._) :void {
            if (newValid == Ternary.TRUE) valid = YES;
            else if (newValid == Ternary.FALSE) valid = ERROR;
            else valid = PENDING;
        });
    }

    public function get isValid () :Boolean { return valid == YES; }

    public function get isModified () :Boolean { return modified == YES; }

    public function updateModified (newModified :Ternary) :void {
        changeField("modified", function (..._) :void {
            if (newModified == Ternary.TRUE) modified = YES;
            else if (newModified == Ternary.FALSE) modified = " ";
            else modified = PENDING;
        });
    }

    protected function changeField(fieldName :String, modifier :Function) :void {
        const oldValue :Object = this[fieldName];
        modifier();
        const newValue :Object = this[fieldName];
        dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, fieldName, oldValue, newValue));
    }

    public function get uid () :String { return _uid; }
    public function set uid (uid :String) :void { _uid = uid; }

    protected var _uid :String;

    protected static const PENDING :String = "...";
    protected static const ERROR :String = "ERROR";
    protected static const YES :String = "Yes";
}
}
