//
// Flump - Copyright 2013 Flump Authors
package flump.mold {

/** @private */
public class KeyframeMold
{
    public var index :int;

    /** The length of this keyframe in frames. */
    public var duration :int;

    /**
     * The symbol of the image or movie in this keyframe, or null if there is nothing in it.
     * For flipbook frames, this will be a name constructed out of the movie and frame index.
     */
    public var ref :String;

    /** The label on this keyframe, or null if there isn't one */
    public var label :String;

    /** Exploded values from matrix */
    public var x :Number = 0.0, y :Number = 0.0, scaleX :Number = 1.0, scaleY :Number = 1.0,
        skewX :Number = 0.0, skewY :Number = 0.0;

    /** Transformation point */
    public var pivotX :Number = 0.0, pivotY :Number = 0.0;

    public var alpha :Number = 1;

    public var visible :Boolean = true;

    /** Is this keyframe tweened? */
    public var tweened :Boolean = true;

    /** Tween easing. Only valid if tweened==true. */
    public var ease :Number = 0;

    public static function fromJSON (o :Object) :KeyframeMold {
        const mold :KeyframeMold = new KeyframeMold();
        mold.index = require(o, "index");
        mold.duration = require(o, "duration");
        extractField(o, mold, "ref");
        extractFields(o, mold, "loc", "x", "y");
        extractFields(o, mold, "scale", "scaleX", "scaleY");
        extractFields(o, mold, "skew", "skewX", "skewY");
        extractFields(o, mold, "pivot", "pivotX", "pivotY");
        extractField(o, mold, "alpha");
        extractField(o, mold, "visible");
        extractField(o, mold, "ease");
        extractField(o, mold, "tweened");
        extractField(o, mold, "label");
        return mold;
    }

    /** True if this keyframe does not display anything. */
    public function get isEmpty () :Boolean { return this.ref == null; }

    public function get rotation () :Number { return skewX; }
    // public function set rotation (angle :Number) :void { skewX = skewY = angle; }

    public function rotate (delta :Number) :void {
        skewX += delta;
        skewY += delta;
    }

    public function toJSON (_:*) :Object {
        var json :Object = {
            index: index,
            duration: duration
        };
        if (ref != null) {
            json.ref = ref;
            if (x != 0 || y != 0) json.loc = [round(x), round(y)];
            if (scaleX != 1 || scaleY != 1) json.scale = [round(scaleX), round(scaleY)];
            if (skewX != 0 || skewY != 0) json.skew = [round(skewX), round(skewY)];
            if (pivotX != 0 || pivotY != 0) json.pivot = [round(pivotX), round(pivotY)];
            if (alpha != 1) json.alpha = round(alpha);
            if (!visible) json.visible = visible;
            if (!tweened) json.tweened = tweened;
            if (ease != 0) json.ease = round(ease);
        }
        if (label != null) json.label = label;
        return json;
    }

    public function toXML () :XML {
        var xml :XML = <kf duration={duration}/>;
        if (ref != null) {
            xml.@ref = ref;
            if (x != 0 || y != 0) xml.@loc = "" + round(x) + "," + round(y);
            if (scaleX != 1 || scaleY != 1) xml.@scale = "" + round(scaleX) + "," + round(scaleY);
            if (skewX != 0 || skewY != 0) xml.@skew = "" + round(skewX) + "," + round(skewY);
            if (pivotX != 0 || pivotY != 0) xml.@pivot = "" + round(pivotX) + "," + round(pivotY);
            if (alpha != 1) xml.@alpha = round(alpha);
            if (!visible) xml.@visible = visible;
            if (!tweened) xml.@tweened = tweened;
            if (ease != 0) xml.@ease = round(ease);
        }
        if (label != null) xml.@label = label;
        return xml;
    }

    protected static function extractFields(o :Object, destObj :Object, source :String,
        dest1 :String, dest2 :String) :void {
        const extracted :* = o[source];
        if (extracted === undefined) return;
        destObj[dest1] = extracted[0];
        destObj[dest2] = extracted[1];
    }

    protected static function extractField(o :Object, destObj :Object, field :String) :void {
        const extracted :* = o[field];
        if (extracted === undefined) return;
        destObj[field] = extracted;
    }

    protected static function round (n :Number, places :int = 4) :Number {
        const shift :int = Math.pow(10, places);
        return Math.round(n * shift) / shift;
    }

}
}
