//
// Flump - Copyright 2012 Three Rings Design

package flump.display {

import flump.mold.MovieMold;

import org.osflash.signals.Signal;

import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Sprite;
import starling.events.Event;

public class Movie extends Sprite
{
    public const labelPassed :Signal = new Signal(String);

    public function Movie (src :MovieMold, frameRate :Number, idToDisplayObject :Function) {
        name = src.libraryItem;
        _labels = src.labels;
        _frameRate = frameRate;
        _ticker = new Ticker(advanceTime);
        const flipbook :Boolean = src.flipbook;
        if (src.flipbook) {
            _layers = new Vector.<Layer>(1, true);
            _layers[0] = new Layer(this, src.layers[0], idToDisplayObject, /*flipbook=*/true);
            _frames = src.layers[0].frames;
        } else {
            _layers = new Vector.<Layer>(src.layers.length, true);
            for (var ii :int = 0; ii < _layers.length; ii++) {
                _layers[ii] = new Layer(this, src.layers[ii], idToDisplayObject, /*flipbook=*/false);
                _frames = Math.max(src.layers[ii].frames, _frames);
            }
        }
        _duration = _frames / _frameRate;
        goto(0, true, false);
        addEventListener(Event.ADDED_TO_STAGE, addedToStage);
        addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
    }

    public function frames () :int { return _frames; }

    protected function advanceTime (dt :Number) :void {
        if (!_playing) return;

        _playTime += dt;
        var actualPlaytime :Number = _playTime;
        if (_playTime > _duration) _playTime = _playTime % _duration;
        var newFrame :int = int(_playTime * _frameRate);
        const overDuration :Boolean = dt >= _duration;
        // If the update crosses or goes to the stopFrame, go to the stop frame, stop the movie and
        // clear it
        if (_stopFrame != NO_FRAME) {
            // how many frames remain to the stopframe?
            var framesRemaining :int =
                (_frame <= _stopFrame ? _stopFrame - _frame : _frames - _frame + _stopFrame);
            var framesElapsed :int = int(actualPlaytime * _frameRate) - _frame;
            if (framesElapsed >= framesRemaining) {
                _playing = false;
                newFrame = _stopFrame;
                _stopFrame = NO_FRAME;
            }
        }
        goto(newFrame, false, overDuration);
    }

    protected function goto (newFrame :int, fromSkip :Boolean, overDuration :Boolean) :void {
        if (_goingToFrame) {
            _pendingFrame = newFrame;
            return;
        }
        _goingToFrame = true;
        const differentFrame :Boolean = newFrame != _frame;
        const wrapped :Boolean = newFrame < _frame;
        if (differentFrame) {
            if (wrapped) {
                for each (var layer :Layer in _layers) {
                    layer.changedKeyframe = true;
                    layer.keyframeIdx = 0;
                }
            }
            for each (layer in _layers) layer.drawFrame(newFrame);
        }

        // Update the frame before firing, so if firing changes the frame, it sticks.
        const oldFrame :int = _frame;
        _frame = newFrame;
        if (fromSkip) {
            fireLabels(newFrame, newFrame);
            _playTime = newFrame/_frameRate;
        } else if (overDuration) {
            fireLabels(oldFrame + 1, _frames - 1);
            fireLabels(0, _frame);
        } else if (differentFrame) {
            if (wrapped) {
                fireLabels(oldFrame + 1, _frames - 1);
                fireLabels(0, _frame);
            } else {
                fireLabels(oldFrame + 1, _frame);
            }
        }
        _goingToFrame = false;
        if (_pendingFrame != NO_FRAME) {
            newFrame = _pendingFrame;
            _pendingFrame = NO_FRAME;
            goto(newFrame, true, false);
        }

    }

    protected function fireLabels (startFrame :int, endFrame :int) :void {
        for (var ii :int = startFrame; ii <= endFrame; ii++) {
            if (_labels[ii] == null) continue;
            for each (var label :String in _labels[ii]) labelPassed.dispatch(label);
        }
    }

    protected function addedToStage (..._) :void { Starling.juggler.add(_ticker); }

    protected function removedFromStage (..._) :void { Starling.juggler.add(_ticker); }

    protected var _goingToFrame :Boolean;
    protected var _pendingFrame :int = NO_FRAME;
    protected var _frame :int = NO_FRAME, _stopFrame :int = NO_FRAME;
    protected var _playing :Boolean = true;
    protected var _playTime :Number, _duration :Number;
    protected var _layers :Vector.<Layer>;
    protected var _ticker :Ticker;
    protected var _frames :int;
    protected var _frameRate :Number;
    protected var _labels :Vector.<Vector.<String>>;

    private static const NO_FRAME :int = -1;
}
}
import flump.display.Movie;
import flump.mold.KeyframeMold;
import flump.mold.LayerMold;

import starling.display.DisplayObject;
import starling.display.Sprite;

class Layer {
    public var keyframeIdx :int ;// The index of the last keyframe drawn in drawFrame
    public var layerIdx :int;// This layer's index in the movie
    public var keyframes :Vector.<KeyframeMold>;
    // Only created if there are multiple items on this layer. If it does exist, the appropriate display is swapped in at keyframe changes. If it doesn't, the display is only added to the parent on layer creation
    public var displays :Vector.<DisplayObject>;// <SPDisplayObject*>
    public var movie :Movie; // The movie this layer belongs to
    // If the keyframe has changed since the last drawFrame
    public var changedKeyframe :Boolean;

    public function Layer (movie :Movie, src :LayerMold, idToDisplayObject :Function,
            flipbook :Boolean) {
        keyframes = src.keyframes;
        this.movie = movie;
        var lastItem :String;
        for (var ii :int = 0; ii < keyframes.length && lastItem == null; ii++) {
            lastItem = keyframes[ii].id;
        }
        if (!flipbook && lastItem == null) movie.addChild(new Sprite());// Label only layer
        else {
            var multipleItems :Boolean = flipbook;
            for (ii = 0; ii < keyframes.length && !multipleItems; ii++) {
                multipleItems = keyframes[ii].id != lastItem;
            }
            if (!multipleItems) movie.addChild(idToDisplayObject(lastItem));
            else {
                displays = new Vector.<DisplayObject>();
                for each (var kf :KeyframeMold in keyframes) {
                    var display :DisplayObject = kf.id == null ? new Sprite() : idToDisplayObject(kf.id);
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
        if (keyframeIdx == keyframes.length - 1 || kf.index == frame) {
            layer.x = kf.x;
            layer.y = kf.y;
            layer.scaleX = kf.scaleX;
            layer.scaleY = kf.scaleY;
            layer.rotation = kf.rotation;
            layer.alpha = kf.alpha;
        } else {
            var interped :Number = (frame - kf.index)/kf.duration;
            var ease :Number = kf.ease;
            if (ease != 0) {
                var t :Number;
                if (ease < 0) {
                    // Ease in
                    var inv :Number = 1 - interped;
                    t = 1 - inv*inv;
                    ease = -ease;
                } else {
                    // Ease out
                    t = interped*interped;
                }
                interped = ease*t + (1 - ease)*interped;
            }

            const nextKf :KeyframeMold = keyframes[keyframeIdx + 1];
            layer.x = kf.x + (nextKf.x - kf.x) * interped;
            layer.y = kf.y + (nextKf.y - kf.y) * interped;
            layer.scaleX = kf.scaleX + (nextKf.scaleX - kf.scaleX) * interped;
            layer.scaleY = kf.scaleY + (nextKf.scaleY - kf.scaleY) * interped;
            layer.rotation = kf.rotation + (nextKf.rotation - kf.rotation) * interped;
            layer.alpha = kf.alpha + (nextKf.alpha - kf.alpha) * interped;
        }

        layer.pivotX = kf.pivotX;
        layer.pivotY = kf.pivotY;
        layer.visible = kf.visible;
    }
}

import starling.animation.IAnimatable;

class Ticker implements IAnimatable {
    public function Ticker (callback :Function) {
        _callback = callback;
    }

    public function get isComplete () :Boolean { return false; }

    public function advanceTime (time :Number) :void { _callback(time); }

    protected var _callback :Function;
}
