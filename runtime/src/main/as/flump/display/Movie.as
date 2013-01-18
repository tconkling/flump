//
// Flump - Copyright 2013 Flump Authors

package flump.display {

import flump.mold.MovieMold;

import org.osflash.signals.Signal;

import starling.animation.IAnimatable;
import starling.display.DisplayObject;
import starling.display.Sprite;
import starling.events.Event;

/**
 * A movie created from flump-exported data. It has children corresponding to the layers in the
 * movie in Flash, in the same order and with the same names. It fills in those children
 * initially with the image or movie of the symbol on that exported layer. After the initial
 * population, it only applies the keyframe-based transformations to the child at the index
 * corresponding to the layer. This means it's safe to swap in other DisplayObjects at those
 * positions to have them animated in place of the initial child.
 *
 * <p>A Movie will not animate unless it's added to a Juggler (or its advanceTime() function
 * is otherwise called). When the movie is added to a juggler, it advances its playhead with the
 * frame ticks if isPlaying is true. It will automatically remove itself from its juggler when
 * removed from the stage.</p>
 *
 * @see Library and LibraryLoader to create instances of Movie.
 */
public class Movie extends Sprite
    implements IAnimatable
{
    /** A label fired by all movies when entering their first frame. */
    public static const FIRST_FRAME :String = "flump.movie.FIRST_FRAME";

    /** A label fired by all movies when entering their last frame. */
    public static const LAST_FRAME :String = "flump.movie.LAST_FRAME";

    /** Fires the label string whenever it's passed in playing. */
    public const labelPassed :Signal = new Signal(String);

    /** @private */
    public function Movie (src :MovieMold, frameRate :Number, library :Library) {
        name = src.id;
        _labels = src.labels;
        _frameRate = frameRate;
        if (src.flipbook) {
            _layers = new Vector.<Layer>(1, true);
            _layers[0] = new Layer(this, src.layers[0], library, /*flipbook=*/true);
            _frames = src.layers[0].frames;
        } else {
            _layers = new Vector.<Layer>(src.layers.length, true);
            for (var ii :int = 0; ii < _layers.length; ii++) {
                _layers[ii] = new Layer(this, src.layers[ii], library, /*flipbook=*/false);
                _frames = Math.max(src.layers[ii].frames, _frames);
            }
        }
        _duration = _frames / _frameRate;
        updateFrame(0, /*fromSkip=*/true, /*overDuration=*/false);

        // When we're removed from the stage, remove ourselves from any juggler animating us.
        addEventListener(Event.REMOVED_FROM_STAGE, function (..._) :void {
            dispatchEventWith(Event.REMOVE_FROM_JUGGLER);
        });
    }

    /** @return the frame being displayed. */
    public function get frame () :int { return _frame; }

    /** @return the number of frames in the movie. */
    public function get frames () :int { return _frames; }

    /** @return true if the movie is currently playing. */
    public function get isPlaying () :Boolean { return _playing; }

    /** Plays the movie from its current frame. The movie will loop forever.  */
    public function loop () :Movie {
        _playing = true;
        _stopFrame = NO_FRAME;
        return this;
    }

    /** Plays the movie from its current frame, stopping when it reaches its last frame. */
    public function playOnce () :Movie { return playTo(LAST_FRAME); }

    /**
     * Moves to the given String label or int frame. Doesn't alter playing status or stop frame.
     * If there are labels at the given position, they're fired as part of the goto, even if the
     * current frame is equal to the destination. Labels between the current frame and the
     * destination frame are not fired.
     *
     * @param position the int frame or String label to goto.
     *
     * @return this movie for chaining
     *
     * @throws Error if position isn't an int or String, or if it is a String and that String isn't
     * a label on this movie
     */
    public function goTo (position :Object) :Movie {
        const frame :int = extractFrame(position);
        updateFrame(frame, /*fromSkip=*/true, /*overDuration=*/false);
        return this;
    }

   /**
    * Plays the movie from its current frame. The movie will stop when it reaches the given label
    * or frame.
    *
    * @param position to int frame or String label to stop at
    *
    * @return this movie for chaining
    *
    * @throws Error if position isn't an int or String, or if it is a String and that String isn't
    * a label on this movie.
    */
    public function playTo (position :Object) :Movie {
       _stopFrame = extractFrame(position);
       _playing = true;
       return this;
    }

    /** Stops playback if it's currently active. Doesn't alter the current frame or stop frame. */
    public function stop () :Movie {
        _playing = false;
        return this;
    }

    /** Advances the playhead by the give number of seconds. From IAnimatable. */
    public function advanceTime (dt :Number) :void {
        if (!_playing) return;

        _playTime += dt;
        var actualPlaytime :Number = _playTime;
        if (_playTime >= _duration) _playTime = _playTime % _duration;

        // If _playTime is very close to _duration, rounding error can cause us to
        // land on lastFrame + 1. Protect against that.
        var newFrame :int = Math.min(int(_playTime * _frameRate), _frames - 1);

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
        updateFrame(newFrame, false, overDuration);

        for (var ii :int = 0; ii < this.numChildren; ++ii) {
            var child :DisplayObject = getChildAt(ii);
            if (child is Movie) {
                Movie(child).advanceTime(dt);
            }
        }
    }

    /** @private */
    protected function extractFrame (position :Object) :int {
        if (position is int) return int(position);
        if (!(position is String)) throw new Error("Movie position must be an int frame or String label");
        const label :String = String(position);
        for (var ii :int = 0; ii < _labels.length; ii++) {
            if (_labels[ii] != null && _labels[ii].indexOf(label) != -1) return ii;
        }
        throw new Error("No such label '" + label + "'");
    }

    /** @private */
    protected function updateFrame (newFrame :int, fromSkip :Boolean, overDuration :Boolean) :void {
        if (newFrame >= _frames) {
            throw new Error("Asked to go to frame " + newFrame + " past the last frame, " +
                (_frames - 1));
        }
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
            } else fireLabels(oldFrame + 1, _frame);
        }
        _goingToFrame = false;
        if (_pendingFrame != NO_FRAME) {
            newFrame = _pendingFrame;
            _pendingFrame = NO_FRAME;
            updateFrame(newFrame, true, false);
        }

    }

    /** @private */
    protected function fireLabels (startFrame :int, endFrame :int) :void {
        for (var ii :int = startFrame; ii <= endFrame; ii++) {
            if (_labels[ii] == null) continue;
            for each (var label :String in _labels[ii]) labelPassed.dispatch(label);
        }
    }

    /** @private */
    protected var _goingToFrame :Boolean;
    /** @private */
    protected var _pendingFrame :int = NO_FRAME;
    /** @private */
    protected var _frame :int = NO_FRAME, _stopFrame :int = NO_FRAME;
    /** @private */
    protected var _playing :Boolean = true;
    /** @private */
    protected var _playTime :Number, _duration :Number;
    /** @private */
    protected var _layers :Vector.<Layer>;
    /** @private */
    protected var _frames :int;
    /** @private */
    protected var _frameRate :Number;
    /** @private */
    protected var _labels :Vector.<Vector.<String>>;

    private static const NO_FRAME :int = -1;
}
}

import flump.display.Library;
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
            layer.skewX = kf.skewX + (nextKf.skewX - kf.skewX) * interped;
            layer.skewY = kf.skewY + (nextKf.skewY - kf.skewY) * interped;
            layer.alpha = kf.alpha + (nextKf.alpha - kf.alpha) * interped;
        }

        layer.pivotX = kf.pivotX;
        layer.pivotY = kf.pivotY;
        layer.visible = kf.visible;
    }
}
