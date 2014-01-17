//
// Flump - Copyright 2013 Flump Authors

package flump.display {

import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import flump.mold.LayerMold;
import flump.mold.MovieMold;

import react.Signal;

import starling.animation.IAnimatable;
import starling.display.DisplayObject;
import starling.display.Sprite;
import starling.events.Event;
import starling.utils.MatrixUtil;

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
        this.name = src.id;
        _labels = src.labels;
        _frameRate = frameRate;
        if (src.flipbook) {
            _layers = new Vector.<Layer>(1, true);
            _layers[0] = createLayer(this, src.layers[0], library, /*flipbook=*/true);
            _numFrames = src.layers[0].frames;
        } else {
            _layers = new Vector.<Layer>(src.layers.length, true);
            for (var ii :int = 0; ii < _layers.length; ii++) {
                _layers[ii] = createLayer(this, src.layers[ii], library, /*flipbook=*/false);
                _numFrames = Math.max(src.layers[ii].frames, _numFrames);
            }
        }
        _duration = _numFrames / _frameRate;
        updateFrame(0, 0);

        // When we're removed from the stage, remove ourselves from any juggler animating us.
        addEventListener(Event.REMOVED_FROM_STAGE, function (..._) :void {
            dispatchEventWith(Event.REMOVE_FROM_JUGGLER);
        });
    }

    /** @return the frame being displayed. */
    public function get frame () :int { return _frame; }

    /** @return the number of frames in the movie. */
    public function get numFrames () :int { return _numFrames; }

    /** @return true if the movie is currently playing. */
    public function get isPlaying () :Boolean { return _state == PLAYING; }

    /** @return true if the movie contains the given label. */
    public function hasLabel (label :String) :Boolean {
        return getFrameForLabel(label) >= 0;
    }

    /** Plays the movie from its current frame. The movie will loop forever.  */
    public function loop () :Movie {
        _state = PLAYING;
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
        updateFrame(frame, 0);
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
       // won't play if we're already at the stop position
       return stopAt(position).play();
    }

    /**
     * Sets the stop frame for this Movie.
     *
     * @param position the int frame or String label to stop at.
     *
     * @return this movie for chaining
     *
     * @throws Error if position isn't an int or String, or if it is a String and that String isn't
     * a label on this movie.
     */
    public function stopAt (position :Object) :Movie {
        _stopFrame = extractFrame(position);
        return this;
    }

    /**
     * Sets the movie playing. It will automatically stop at its stopFrame, if one is set,
     * otherwise it will loop forever.
     *
     * @return this movie for chaining
     */
    public function play () :Movie {
        // set playing to true unless movie is at the stop frame
        _state = (_frame != _stopFrame ? PLAYING : STOPPED);
        return this;
    }

    /** Stops playback if it's currently active. Doesn't alter the current frame or stop frame. */
    public function stop () :Movie {
        _state = STOPPED;
        return this;
    }

    /** Stops playback of this movie, but not its children */
    public function playChildrenOnly () :Movie {
        _state = PLAYING_CHILDREN_ONLY;
        return this;
    }

    /** Advances the playhead by the give number of seconds. From IAnimatable. */
    public function advanceTime (dt :Number) :void {
        if (dt < 0) throw new Error("Invalid time [dt=" + dt + "]");
        if (_skipAdvanceTime) { _skipAdvanceTime = false; return; }
        if (_state == STOPPED) return;

        if (_state == PLAYING && _numFrames > 1) {
            _playTime += dt;
            var actualPlaytime :Number = _playTime;
            if (_playTime >= _duration) _playTime %= _duration;

            // If _playTime is very close to _duration, rounding error can cause us to
            // land on lastFrame + 1. Protect against that.
            var newFrame :int = int(_playTime * _frameRate);
            if (newFrame < 0) newFrame = 0;
            if (newFrame >= _numFrames) newFrame = _numFrames - 1;

            // If the update crosses or goes to the stopFrame:
            // go to the stopFrame, stop the movie, clear the stopFrame
            if (_stopFrame != NO_FRAME) {
                // how many frames remain to the stopframe?
                var framesRemaining :int =
                    (_frame <= _stopFrame ? _stopFrame - _frame : _numFrames - _frame + _stopFrame);
                var framesElapsed :int = int(actualPlaytime * _frameRate) - _frame;
                if (framesElapsed >= framesRemaining) {
                    _state = STOPPED;
                    newFrame = _stopFrame;
                }
            }
            updateFrame(newFrame, dt);
        }

        for each (var layer :Layer in _layers) {
            layer.advanceTime(dt);
        }
    }

    /**
     * @public
     *
     * Modified from starling.display.DisplayObjectContainer
     */
    public override function getBounds (targetSpace :DisplayObject, resultRect :Rectangle=null) :Rectangle {
        if (resultRect == null) {
            resultRect = new Rectangle();
        } else {
            resultRect.setEmpty();
        }

        // get bounds from layer contents
        for each (var layer :Layer in _layers) {
            layer.expandBounds(targetSpace, resultRect);
        }

        // if no contents exist, simply include this movie's position in the bounds
        if (resultRect.isEmpty()) {
            getTransformationMatrix(targetSpace, IDENTITY_MATRIX);
            MatrixUtil.transformCoords(IDENTITY_MATRIX, 0.0, 0.0, _s_helperPoint);
            resultRect.setTo(_s_helperPoint.x, _s_helperPoint.y, 0, 0);
        }

        return resultRect;
    }

    /**
     * @private
     *
     * Called when the Movie has been newly added to a layer.
     */
    internal function addedToLayer () :void {
        goTo(0);
        _skipAdvanceTime = true;
    }

    /** @private */
    protected function extractFrame (position :Object) :int {
        if (position is int) return int(position);
        if (!(position is String)) throw new Error("Movie position must be an int frame or String label");
        const label :String = String(position);
        var frame :int = getFrameForLabel(label);
        if (frame < 0) {
            throw new Error("No such label '" + label + "'");
        }
        return frame;
    }

    /**
     * @private
     *
     * Returns the frame index for the given label, or -1 if the label doesn't exist.
     */
    protected function getFrameForLabel (label :String) :int {
        for (var ii :int = 0; ii < _labels.length; ii++) {
            if (_labels[ii] != null && _labels[ii].indexOf(label) != -1) return ii;
        }
        return -1;
    }

    /**
     * @private
     *
     * @param dt the timeline's elapsed time since the last update. This should be 0
     * for updates that are the result of a "goTo" call.
     */
    protected function updateFrame (newFrame :int, dt :Number) :void {
        if (newFrame < 0 || newFrame >= _numFrames) {
            throw new Error("Invalid frame [frame=" + newFrame,
                " validRange=0-" + (_numFrames - 1) + "]");
        }

        if (_isUpdatingFrame) {
            _pendingFrame = newFrame;
            return;
        } else {
            _pendingFrame = NO_FRAME;
            _isUpdatingFrame = true;
        }

        const isGoTo :Boolean = (dt <= 0);
        const wrapped :Boolean = (dt >= _duration) || (newFrame < _frame);

        if (newFrame != _frame) {
            if (wrapped) {
                for each (var layer :Layer in _layers) {
                    layer.movieLooped();
                }
            }
            for each (layer in _layers) layer.drawFrame(newFrame);
        }

        if (isGoTo) _playTime = newFrame / _frameRate;

        // Update the frame before firing frame label signals, so if firing changes the frame,
        // it sticks.
        const oldFrame :int = _frame;
        _frame = newFrame;

        // determine which labels to fire signals for
        var startFrame :int;
        var frameCount :int;
        if (isGoTo) {
            startFrame = newFrame;
            frameCount = 1;
        } else {
            startFrame = (oldFrame + 1 < _numFrames ? oldFrame + 1 : 0);
            frameCount = (_frame - oldFrame);
            if (wrapped) frameCount += _numFrames;
        }

        // Fire signals. Stop if pendingFrame is updated, which indicates that the client
        // has called goTo()
        var frameIdx :int = startFrame;
        for (var ii :int = 0; ii < frameCount; ++ii) {
            if (_pendingFrame != NO_FRAME) break;

            if (_labels[frameIdx] != null) {
                for each (var label :String in _labels[frameIdx]) {
                    labelPassed.emit(label);
                    if (_pendingFrame != NO_FRAME) break;
                }
            }

            // avoid modulo division by updating frameIdx each time through the loop
            if (++frameIdx == _numFrames) {
                frameIdx = 0;
            }
        }

        _isUpdatingFrame = false;
        // If we were interrupted by a goTo(), update to that frame now.
        if (_pendingFrame != NO_FRAME) {
            newFrame = _pendingFrame;
            updateFrame(newFrame, 0);
        }
    }

    protected function createLayer (movie :Movie, src :LayerMold, library :Library, flipbook :Boolean) :Layer {
        return new Layer(movie, src, library, flipbook);
    }

    /** @private */
    protected var _isUpdatingFrame :Boolean;
    /** @private */
    protected var _pendingFrame :int = NO_FRAME;
    /** @private */
    protected var _frame :int = NO_FRAME, _stopFrame :int = NO_FRAME;
    /** @private */
    protected var _state :int = PLAYING;
    /** @private */
    protected var _playTime :Number, _duration :Number;
    /** @private */
    protected var _layers :Vector.<Layer>;
    /** @private */
    protected var _numFrames :int;
    /** @private */
    protected var _frameRate :Number;
    /** @private */
    protected var _labels :Vector.<Vector.<String>>;
    /** @private */
    private var _skipAdvanceTime :Boolean = false;
    /** @private */
    internal var _playerData :MoviePlayerNode;
    /** @private */
    private static var _s_helperPoint :Point = new Point();

    private static const IDENTITY_MATRIX :Matrix = new Matrix();

    private static const NO_FRAME :int = -1;

    private static const STOPPED :int = 0;
    private static const PLAYING_CHILDREN_ONLY :int = 1;
    private static const PLAYING :int = 2;
}
}

