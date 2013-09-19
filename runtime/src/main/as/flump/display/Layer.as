package flump.display {

import flump.mold.KeyframeMold;
import flump.mold.LayerMold;

import starling.display.DisplayObject;
import starling.display.Sprite;

/**
 * A logical wrapper around the DisplayObject(s) residing on the timeline of a single layer of a
 * Movie. Responsible for efficiently managing the creation and display of the DisplayObjects for
 * this layer on each frame.
 */
internal class Layer {
    public var keyframeIdx :int;// The index of the last keyframe drawn in drawFrame
    public var layerIdx :int;// This layer's index in the movie
    public var keyframes :Vector.<KeyframeMold>;
    // Only created if there are multiple items on this layer. If it does exist, the appropriate
    // display is swapped in at keyframe changes. If it doesn't, the display is only added to the
    // parent on layer creation
    public var displays :Vector.<DisplayObject>;
    public var movie :Movie; // The movie this layer belongs to
    // true if the keyframe has changed since the last drawFrame
    public var changedKeyframe :Boolean;

    public function Layer (movie :Movie, src :LayerMold, library :Library, flipbook :Boolean) {
        keyframes = src.keyframes;
        this.movie = movie;
        var lastItem :String;
        for (var ii :int = 0; ii < keyframes.length && lastItem == null; ii++) {
            lastItem = keyframes[ii].ref;
        }
        if (!flipbook && lastItem == null) movie.addChild(new Sprite());// Label only layer
        else {
            var multipleItems :Boolean = flipbook;
            for (ii = 0; ii < keyframes.length && !multipleItems; ii++) {
                multipleItems = keyframes[ii].ref != lastItem;
            }
            if (!multipleItems) movie.addChild(library.createDisplayObject(lastItem));
            else {
                displays = new <DisplayObject>[];
                for each (var kf :KeyframeMold in keyframes) {
                    var display :DisplayObject =
                        (kf.ref == null ? new Sprite() : library.createDisplayObject(kf.ref));
                    displays.push(display);
                    display.name = src.name;
                }
                movie.addChild(displays[0]);
            }
        }
        layerIdx = movie.numChildren - 1;
        movie.getChildAt(layerIdx).name = src.name;
    }

    public function drawFrame (frame :int) :void {
        while (keyframeIdx < keyframes.length - 1 && keyframes[keyframeIdx + 1].index <= frame) {
            keyframeIdx++;
            changedKeyframe = true;
        }
        // We've got multiple items. Swap in the one for this kf
        if (changedKeyframe && displays != null) {
            movie.removeChildAt(layerIdx);
            movie.addChildAt(displays[keyframeIdx], layerIdx);
        }
        changedKeyframe = false;
        const kf :KeyframeMold = keyframes[keyframeIdx];
        const layer :DisplayObject = movie.getChildAt(layerIdx);
        if (keyframeIdx == keyframes.length - 1 || kf.index == frame || !kf.tweened) {
            layer.x = kf.x;
            layer.y = kf.y;
            layer.scaleX = kf.scaleX;
            layer.scaleY = kf.scaleY;
            layer.skewX = kf.skewX;
            layer.skewY = kf.skewY;
            layer.alpha = kf.alpha;
        } else {
            var interped :Number = (frame - kf.index) / kf.duration;
            var ease :Number = kf.ease;
            if (ease != 0) {
                var t :Number;
                if (ease < 0) {
                    // Ease in
                    var inv :Number = 1 - interped;
                    t = 1 - inv * inv;
                    ease = -ease;
                } else {
                    // Ease out
                    t = interped * interped;
                }
                interped = ease * t + (1 - ease) * interped;
            }
            const nextKf :KeyframeMold = keyframes[keyframeIdx + 1];
            layer.x = kf.x + (nextKf.x - kf.x) * interped;
            layer.y = kf.y + (nextKf.y - kf.y) * interped;
            layer.scaleX = kf.scaleX + (nextKf.scaleX - kf.scaleX) * interped;
            layer.scaleY = kf.scaleY + (nextKf.scaleY - kf.scaleY) * interped;
            layer.skewX = kf.skewX + (nextKf.skewX - kf.skewX) * interped;
            layer.skewY = kf.skewY + (nextKf.skewY - kf.skewY) * interped;
            layer.alpha = kf.alpha + (nextKf.alpha - kf.alpha) * interped;
        }
        layer.pivotX = kf.pivotX;
        layer.pivotY = kf.pivotY;
        layer.visible = kf.visible;
    }
}
}
