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
    public function Layer (movie :Movie, src :LayerMold, library :Library, flipbook :Boolean) {
        _keyframes = src.keyframes;
        _movie = movie;
        var lastItem :String;
        for (var ii :int = 0; ii < _keyframes.length && lastItem == null; ii++) {
            lastItem = _keyframes[ii].ref;
        }
        if (!flipbook && lastItem == null) {
            // The layer is empty.
            movie.addChild(new Sprite());
        } else {
            // Discover whether we have multiple display items. If not, we don't need
            // to create the 'displays' vector.
            var hasMultipleDisplayItems :Boolean = flipbook;
            for (ii = 0; ii < _keyframes.length && !hasMultipleDisplayItems; ii++) {
                hasMultipleDisplayItems = _keyframes[ii].ref != lastItem;
            }
            if (!hasMultipleDisplayItems) movie.addChild(library.createDisplayObject(lastItem));
            else {
                _displays = new <DisplayObject>[];
                for each (var kf :KeyframeMold in _keyframes) {
                    var display :DisplayObject =
                        (kf.ref == null ? new Sprite() : library.createDisplayObject(kf.ref));
                    _displays.push(display);
                    display.name = src.name;
                }
                movie.addChild(_displays[0]);
            }
        }
        _layerIdx = movie.numChildren - 1;
        movie.getChildAt(_layerIdx).name = src.name;
    }

    /** Called by Movie when we loop. */
    public function movieLooped () :void {
        _changedKeyframe = true;
        _keyframeIdx = 0;
    }

    public function drawFrame (frame :int) :void {
        while (_keyframeIdx < _keyframes.length - 1 && _keyframes[_keyframeIdx + 1].index <= frame) {
            _keyframeIdx++;
            _changedKeyframe = true;
        }
        if (_changedKeyframe && _displays != null) {
            // Swap in the DisplayObject for this keyframe.
            _movie.removeChildAt(_layerIdx);
            _movie.addChildAt(_displays[_keyframeIdx], _layerIdx);
        }

        _changedKeyframe = false;
        const kf :KeyframeMold = _keyframes[_keyframeIdx];
        const layer :DisplayObject = _movie.getChildAt(_layerIdx);
        if (_keyframeIdx == _keyframes.length - 1 || kf.index == frame || !kf.tweened) {
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
            const nextKf :KeyframeMold = _keyframes[_keyframeIdx + 1];
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

    protected var _layerIdx :int;// This layer's index in the movie
    protected var _keyframes :Vector.<KeyframeMold>;
    // Only created if there are multiple items on this layer. If it does exist, the appropriate
    // display is swapped in at keyframe changes. If it doesn't, the display is only added to the
    // parent on layer creation
    protected var _displays :Vector.<DisplayObject>;
    protected var _movie :Movie; // The movie this layer belongs to

    // The index of the last keyframe drawn in drawFrame. Updated in drawFrame. When the parent
    // movie loops, it resets all of its layers' keyframeIdx's to 0.
    protected var _keyframeIdx :int;

    // true if the keyframe has changed since the last drawFrame
    protected var _changedKeyframe :Boolean;
}
}
