//
// Flump - Copyright 2013 Flump Authors

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
            // Create the display objects for each keyframe.
            // If multiple consecutive keyframes refer to the same library item,
            // we reuse that item across those frames.
            _displays = new Vector.<DisplayObject>(_keyframes.length, true);
            for (ii = 0; ii < _keyframes.length; ++ii) {
                var kf :KeyframeMold = _keyframes[ii];
                var display :DisplayObject = null;
                if (ii > 0 && _keyframes[ii - 1].ref == kf.ref) {
                    display = _displays[ii - 1];
                } else if (kf.ref == null) {
                    display = new Sprite();
                } else {
                    display = library.createDisplayObject(kf.ref);
                }
                _displays[ii] = display;
                display.name = src.name;
            }
            movie.addChild(_displays[0]);
        }
        _layerIdx = movie.numChildren - 1;
        movie.getChildAt(_layerIdx).name = src.name;
    }

    /** Called by Movie when we loop. */
    public function movieLooped () :void {
        _needsKeyframeUpdate = true;
        _keyframeIdx = 0;
    }

    public function drawFrame (frame :int) :void {
        if (_displays == null) {
            // We have nothing to display.
            return;

        } else if (frame >= this.numFrames) {
            // We've overshot our final frame. Show an empty sprite.
            if (_frameOvershootDisplay == null) {
                _frameOvershootDisplay = new Sprite();
            }
            if (_movie.getChildAt(_layerIdx) != _frameOvershootDisplay) {
                _movie.removeChildAt(_layerIdx);
                _movie.addChildAt(_frameOvershootDisplay, _layerIdx);
            }
            // keep our keyframeIdx updated
            _keyframeIdx = _keyframes.length - 1;
            _needsKeyframeUpdate = true;
            return;
        }

        while (_keyframeIdx < _keyframes.length - 1 && _keyframes[_keyframeIdx + 1].index <= frame) {
            _keyframeIdx++;
            _needsKeyframeUpdate = true;
        }

        if (_needsKeyframeUpdate) {
            // Swap in the proper DisplayObject for this keyframe.
            const disp :DisplayObject = _displays[_keyframeIdx];
            if (_movie.getChildAt(_layerIdx) != disp) {
                _movie.removeChildAt(_layerIdx);
                // If we're swapping in a Movie, reset its timeline.
                if (disp is Movie) {
                    Movie(disp).addedToLayer();
                }
                _movie.addChildAt(disp, _layerIdx);
            }
        }
        _needsKeyframeUpdate = false;

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

    protected function get numFrames () :int {
        const lastKf :KeyframeMold = _keyframes[_keyframes.length - 1];
        return lastKf.index + lastKf.duration;
    }

    protected var _layerIdx :int;// This layer's index in the movie
    protected var _keyframes :Vector.<KeyframeMold>;
    // Stores this layer's DisplayObjects indexed by keyframe.
    protected var _displays :Vector.<DisplayObject>;
    // Created if the layer has fewer frames than its parent movie. If the layer is told to
    // draw a frame past its last frame, it will display this empty sprite.
    protected var _frameOvershootDisplay :Sprite;
    protected var _movie :Movie; // The movie this layer belongs to
    // The index of the last keyframe drawn in drawFrame. Updated in drawFrame. When the parent
    // movie loops, it resets all of its layers' keyframeIdx's to 0.
    protected var _keyframeIdx :int;
    // true if the keyframe has changed since the last drawFrame
    protected var _needsKeyframeUpdate :Boolean;
}
}
