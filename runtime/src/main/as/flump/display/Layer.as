//
// Flump - Copyright 2013 Flump Authors

package flump.display {

import flash.geom.Rectangle;

import flump.mold.KeyframeMold;
import flump.mold.LayerMold;

import starling.animation.IAnimatable;
import starling.display.DisplayObject;
import starling.display.Sprite;

/**
 * A logical wrapper around the DisplayObject(s) residing on the timeline of a single layer of a
 * Movie. Responsible for efficiently managing the creation and display of the DisplayObjects for
 * this layer on each frame.
 */
internal class Layer
    implements IAnimatable
{
    public function Layer (movie :Movie, src :LayerMold, library :Library, flipbook :Boolean) {
        _keyframes = src.keyframes;
        _movie = movie;
        _name = src.name;

        const lastKf :KeyframeMold = _keyframes[_keyframes.length - 1];
        _numFrames = lastKf.index + lastKf.duration;

        var lastItem :String;
        for (var ii :int = 0; ii < _keyframes.length && lastItem == null; ii++) {
            lastItem = _keyframes[ii].ref;
        }
        if (!flipbook && lastItem == null) {
            // The layer is empty.
            _currentDisplay = new Sprite();
            _movie.addChild(_currentDisplay);
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
                display.visible = false;
                _movie.addChild(display);
            }
            _currentDisplay = _displays[0];
            _currentDisplay.visible = true;
        }

        _currentDisplay.name = _name;
    }

    /** Called by Movie when we loop. */
    public function movieLooped () :void {
        _needsKeyframeUpdate = true;
        _keyframeIdx = 0;
    }

    /** Advances the playhead by the give number of seconds. From IAnimatable. */
    public function advanceTime (dt :Number) :void {
        if (_currentDisplay is IAnimatable) {
            IAnimatable(_currentDisplay).advanceTime(dt);
        }
    }

    public function drawFrame (frame :int) :void {
        if (_displays == null) {
            // We have nothing to display.
            return;

        } else if (frame >= _numFrames) {
            // We've overshot our final frame. Hide the display
            _currentDisplay.visible = false;
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
            if (_currentDisplay != disp) {
                _currentDisplay.name = null;
                _currentDisplay.visible = false;
                // If we're swapping in a Movie, reset its timeline.
                if (disp is Movie) {
                    Movie(disp).addedToLayer();
                }
                _currentDisplay = disp;
                _currentDisplay.name = _name;
            }
        }
        _needsKeyframeUpdate = false;

        const kf :KeyframeMold = _keyframes[_keyframeIdx];
        const layer :DisplayObject = _currentDisplay;
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

    /** Expands the given bounds to include the bounds of this Layer's current display object. */
    internal function expandBounds (targetSpace :DisplayObject, resultRect :Rectangle) :Rectangle {
        // if no objects on this frame, do not change bounds
        if (_keyframes[_keyframeIdx].ref == null) {
            return resultRect;
        }

        // if no rect was incoming, the resulting bounds is exactly the bounds of the display
        if (resultRect.isEmpty()) {
            return _currentDisplay.getBounds(targetSpace, resultRect);
        }

        // otherwise expand bounds by current display's bounds, if it has any
        var layerRect :Rectangle = _currentDisplay.getBounds(targetSpace);
        if (layerRect.left < resultRect.left) resultRect.left = layerRect.left;
        if (layerRect.right > resultRect.right) resultRect.right = layerRect.right;
        if (layerRect.top < resultRect.top) resultRect.top = layerRect.top;
        if (layerRect.bottom > resultRect.bottom) resultRect.bottom = layerRect.bottom;

        return resultRect;
    }

    protected var _keyframes :Vector.<KeyframeMold>;
    protected var _numFrames :int;
    // Stores this layer's DisplayObjects indexed by keyframe.
    protected var _displays :Vector.<DisplayObject>;
    // The current DisplayObject being rendered for this layer
    protected var _currentDisplay :DisplayObject;
    protected var _movie :Movie; // The movie this layer belongs to
    // The index of the last keyframe drawn in drawFrame. Updated in drawFrame. When the parent
    // movie loops, it resets all of its layers' keyframeIdx's to 0.
    protected var _keyframeIdx :int;
    // true if the keyframe has changed since the last drawFrame
    protected var _needsKeyframeUpdate :Boolean;
    // name of the layer
    protected var _name :String;
}
}
