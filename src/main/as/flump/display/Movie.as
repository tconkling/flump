//
// Flump - Copyright 2012 Three Rings Design

package flump.display {

import flump.xfl.XflMovie;

import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Sprite;
import starling.events.Event;

public class Movie extends Sprite
{
    public function Movie (src :XflMovie, symbolToDisplayObject :Function) {
        name = src.symbol;
        _ticker = new Ticker(advanceTime);
        var frames :int = 0;
        if (src.flipbook) {
            _layers = new Vector.<Layer>(1, true);
            _layers[0] = new Layer(this, src.layers[0], symbolToDisplayObject, true)
            frames = src.layers[0].frames;
        } else {
            _layers = new Vector.<Layer>(src.layers.length, true);
            for (var ii :int = 0; ii < _layers.length; ii++) {
                _layers[ii] = new Layer(this, src.layers[ii], symbolToDisplayObject, false);
                frames = Math.max(src.layers[ii].frames, frames);
            }
        }
        _duration = frames / 30.0;
        goto(0, true, false);
        addEventListener(Event.ADDED_TO_STAGE, addedToStage);
        addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
    }

    protected function advanceTime (dt :Number) :void {
        if (!_playing) return;

        _playTime += dt;
        if (_playTime > _duration) _playTime = _playTime % _duration;
        var newFrame :int = int(_playTime * 30);
        const overDuration :Boolean = dt >= _duration;
        // If the update crosses or goes to the stopFrame, go to the stop frame, stop the movie and
        // clear it
        if (_stopFrame != NO_FRAME &&
            ((newFrame >= _stopFrame && (_frame < _stopFrame || newFrame < _frame)) || overDuration)) {
            _playing = false
            newFrame = _stopFrame;
            _stopFrame = NO_FRAME;
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
            // TODO [self fireLabelsFrom:newFrame to:newFrame];
            _playTime = newFrame/30.0;
        } else if (overDuration) {
            //[self fireLabelsFrom:oldFrame + 1 to:[_labels count] - 1];
            //[self fireLabelsFrom:0 to:_frame];
        } else if (differentFrame) {
            if (wrapped) {
                //[self fireLabelsFrom:oldFrame + 1 to:[_labels count] - 1];
                //[self fireLabelsFrom:0 to:_frame];
            } else {
                //[self fireLabelsFrom:oldFrame + 1 to:_frame];
            }
        }
        _goingToFrame = false;
        if (_pendingFrame != NO_FRAME) {
            newFrame = _pendingFrame;
            _pendingFrame = NO_FRAME;
            goto(newFrame, true, false);
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

    private static const NO_FRAME :int = -1;
}
}
import flump.display.Movie;
import flump.xfl.XflKeyframe;
import flump.xfl.XflLayer;

import starling.display.DisplayObject;
import starling.display.Sprite;

class Layer {
    public var keyframeIdx :int ;// The index of the last keyframe drawn in drawFrame
    public var layerIdx :int;// This layer's index in the movie
    public var keyframes :Vector.<XflKeyframe>;
    // Only created if there are multiple symbols on this layer. If it does exist, the appropriate display is swapped in at keyframe changes. If it doesn't, the display is only added to the parent on layer creation
    public var displays :Vector.<DisplayObject>;// <SPDisplayObject*>
    public var movie :Movie; // The movie this layer belongs to
    // If the keyframe has changed since the last drawFrame
    public var changedKeyframe :Boolean;

    public function Layer (movie :Movie, src :XflLayer, createDisplayObject :Function,
            flipbook :Boolean) {
        keyframes = src.keyframes;
        this.movie = movie;
        var lastSymbol :String;
        for (var ii :int = 0; ii < keyframes.length && lastSymbol == null; ii++) {
            lastSymbol = keyframes[ii].symbol;
        }
        if (!flipbook && lastSymbol == null) movie.addChild(new Sprite());// Label only layer
        else {
            var multipleSymbols :Boolean = flipbook;
            for (ii = 0; ii < keyframes.length && !multipleSymbols; ii++) {
                multipleSymbols = keyframes[ii].symbol != lastSymbol;
            }
            if (!multipleSymbols) movie.addChild(createDisplayObject(lastSymbol));
            else {
                displays = new Vector.<DisplayObject>();
                for each (var kf :XflKeyframe in keyframes) {
                    var kfSymbol :String;
                    if (flipbook) kfSymbol = movie.name + "_flipbook_" + kf.index;
                    else kfSymbol = kf.symbol;
                    var display :DisplayObject = createDisplayObject(kfSymbol);
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
        // We've got multiple symbols. Swap in the one for this kf
        if (changedKeyframe && displays != null) {
            movie.removeChildAt(layerIdx);
            movie.addChildAt(displays[keyframeIdx], layerIdx);
        }
        changedKeyframe = false;

        const kf :XflKeyframe = keyframes[keyframeIdx];
        const layer :DisplayObject = movie.getChildAt(layerIdx);
        if (keyframeIdx == keyframes.length - 1|| kf.index == frame) {
            layer.x = kf.x;
            layer.y = kf.y;
            layer.scaleX = kf.scaleX;
            layer.scaleY = kf.scaleY;
            layer.rotation = kf.rotation;
        } else {
            // TODO - interpolation types other than linear
            var interped :Number = (frame - kf.index)/kf.duration;
            const nextKf :XflKeyframe = keyframes[keyframeIdx + 1];
            layer.x = kf.x + (nextKf.x - kf.x) * interped;
            layer.y = kf.y + (nextKf.y - kf.y) * interped;
            layer.scaleX = kf.scaleX + (nextKf.scaleX - kf.scaleX) * interped;
            layer.scaleY = kf.scaleY + (nextKf.scaleY - kf.scaleY) * interped;
            layer.rotation = kf.rotation + (nextKf.rotation - kf.rotation) * interped;
        }
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
