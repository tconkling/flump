//
// Flump - Copyright 2012 Three Rings Design
package flump.mold {

import flash.net.registerClassAlias;

public class KeyframeMold extends Mold
{
    // Make this come out as itself in AMF
    registerClassAlias("KeyframeMold", KeyframeMold);

    public var index :int;

    /** The length of this keyframe in frames. */
    public var duration :Number;

    /** The name of the libraryItem in this keyframe, or null if there is no libraryItem. */
    public var libraryItem :String;

    /** The name of the symbol in this keyframe, or null if there is no symbol. */
    public var symbol :String;

    /**
     * The id by which this keyframe's texture can be found. Either the libraryItem for normal
     * keyframes, or a constructed name for flipbook frames. Since the libraryItem can be null, this
     * can also be null.
     */
    public var id :String;

    /** The label on this keyframe, or null if there isn't one */
    public var label :String;

    /** Exploded values from matrix */
    public var x :Number = 0.0, y :Number = 0.0, scaleX :Number = 1.0, scaleY :Number = 1.0,
        rotation :Number = 0.0;

    /** Transformation point */
    public var pivotX :Number = 0.0, pivotY :Number = 0.0;

    public var alpha :Number = 1;

    public var visible :Boolean = true;

    public var ease :Number = 0;

    public function toJSON (_:*) :Object {
        var json :Object = {
            duration: duration
        };
        if (symbol != null) {
            json.ref = symbol;
            if (x != 0 || y != 0) {
                json.loc = [x, y];
            }
            if (scaleX != 1 || scaleY != 1) {
                json.scale = [scaleX, scaleY];
            }
            if (rotation != 0) {
                json.rotation = rotation;
            }
            if (pivotX != 0 || pivotY != 0) {
                json.pivot = [pivotX, pivotY];
            }
            if (alpha != 1) {
                json.alpha = alpha;
            }
            if (!visible) {
                json.visible = visible;
            }
            if (ease != 0) {
                json.ease = ease;
            }
        }
        if (label != null) {
            json.label = label;
        }
        return json;
    }

    public function toXML () :XML
    {
        var xml :XML = <kf duration={duration}/>;

        if (symbol != null) {
            xml.@ref = symbol;
            if (x != 0 || y != 0) {
                xml.@loc = "" + x + "," + y;
            }
            if (scaleX != 1 || scaleY != 1) {
                xml.@scale = "" + scaleX + "," + scaleY;
            }
            if (rotation != 0) {
                xml.@rotation = rotation;
            }
            if (pivotX != 0 || pivotY != 0) {
                xml.@pivot = "" + pivotX + "," + pivotY;
            }
            if (alpha != 1) {
                xml.@alpha = alpha;
            }
            if (!visible) {
                xml.@visible = visible;
            }
            if (ease != 0) {
                xml.@ease = ease;
            }
        }
        if (label != null) {
            xml.@label = label;
        }
        return xml;
    }

}
}
