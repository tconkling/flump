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
            _layers = new Vector.<Layer>(1);
            _layers[0] = createLayer(this, src.layers[0], library, /*flipbook=*/true);
            _numFrames = src.layers[0].frames;
        } else {
            _layers = new Vector.<Layer>(src.layers.length);
            for (var ii :int = 0; ii < _layers.length; ii++) {
                _layers[ii] = createLayer(this, src.layers[ii], library, /*flipbook=*/false);
                _numFrames = Math.max(src.layers[ii].frames, _numFrames);
            }
        }
        _duration = _numFrames / _frameRate;
        updateFrame(0, 0);

        addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
    }

    /** Called when our REMOVED_FROM_STAGE event is fired. */
    protected function onRemovedFromStage (e :Event) :void {
        // When we're removed from the stage, remove ourselves from any juggler animating us,
        // and note that we're no longer managed by a parent Movie's layer
        dispatchEventWith(Event.REMOVE_FROM_JUGGLER);
        _isManagedByParentMovie = false;
    }

    /**
     * @return true if we're being managed by another movie.
     * This is only the case if this Movie was created by its parent and has never been removed
     * from it. (A Movie that's added to another Movie after creation is *not* managed by its
     * parent.)
     */
    public function get isManagedByParentMovie () :Boolean { return _isManagedByParentMovie; }

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

    /** @return the frame index for the given label, or -1 if the label doesn't exist. */
    public function getFrameForLabel (label :String) :int {
        for (var ii :int = 0; ii < _labels.length; ii++) {
            if (_labels[ii] != null && _labels[ii].indexOf(label) != -1) return ii;
        }
        return -1;
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
        return goToInternal(frame, false);
    }

    /**
     * Calls goTo on this Movie and all its descendent Movies.
     * If the given frame doesn't exist in a descendent movie, that movie will be advanced
     * to its final frame.
     *
     * @param position the int frame or String label to goto.
     *
     * @return this movie for chaining
     *
     * @throws Error if position isn't an int or String, or if it is a String and that String isn't
     * a label on this movie
     */
    public function recursiveGoTo (position :Object) :Movie {
        const frame :int = extractFrame(position);
        return goToInternal(frame, true);
    }

    /**
     * Enables or disables a layer in the Movie.
     *
     * While a layer is disabled, it will not be updated by the Movie. It will still be drawn
     * in its current state, however; this function returns the DisplayObject attached to
     * the given layer, so that it can be hidden (for example) after its layer is disabled.
     *
     * @param name the name of the layer to enable/disable. If there are multiple layers with the
     * given name, only the first (the "lowest") will be modified.
     *
     * @param enabled whether to enable the layer.
     *
     * @return the DisplayObject attached to the layer (or null if no layer with that name exists).
     */
    public function setLayerEnabled (name :String, enabled :Boolean) :DisplayObject {
        for each (var layer :Layer in _layers) {
            if (layer.name == name) {
                layer._disabled = !enabled;
                return layer._currentDisplay;
            }
        }

        return null;
    }

    /**
     * Gets the value of a layer's 'enabled' flag.
     *
     * @param name the name of the layer to query.
     *
     * @return True if the layer is enabled; false if it's disabled or if no such layer exists.
     */
    public function isLayerEnabled (name :String) :Boolean {
        for each (var layer :Layer in _layers) {
            if (layer.name == name) {
                return !layer._disabled;
            }
        }
        return false;
    }

    /**
     * Removes the child at the given index.
     * If that child is on a Layer we manage, and the Layer contains no other DisplayObjects,
     * the entire Layer will be removed from the Movie.
     */
    override public function removeChildAt (index :int, dispose :Boolean = false) :DisplayObject {
        if (_isUpdatingFrame) {
            throw new Error("Can't remove a layer while the Movie is being updated.");
        }

        if (index < 0) {
            index = this.numChildren - index;
        }

        var child :DisplayObject = super.getChildAt(index);

        // Discover if our child is on a managed Layer
        var childLayerIdx :int = -1;
        if (index < _layers.length && _layers[index]._currentDisplay == child) {
            // Common case
            childLayerIdx = index;
        } else {
            for (var ii :int = 0; ii < _layers.length; ++ii) {
                if (_layers[ii]._currentDisplay == child) {
                    childLayerIdx = ii;
                    break;
                }
            }
        }

        var addReplacementDisplayObject :Boolean;
        if (childLayerIdx >= 0) {
            // Child is no longer managed by this Movie
            var childMovie :Movie = (child as Movie);
            if (childMovie != null) {
                childMovie.setParentMovie(null);
            }

            if (_layers[childLayerIdx].numDisplays == 1) {
                // We're removing the only DisplayObject on the layer, which means we can
                // remove the entire layer.
                _layers.removeAt(childLayerIdx);
            } else {
                // The Layer has other DisplayObjects; we need to swap in a replacement
                addReplacementDisplayObject = true;
            }
        }

        super.removeChildAt(index, dispose);

        if (addReplacementDisplayObject) {
            var replacement :DisplayObject = new Sprite();
            addChildAt(replacement, index);
            _layers[childLayerIdx].replaceCurrentDisplay(replacement);
        }

        return child;
    }

    /**
     * Returns the names of this Movie's layers.
     *
     * @param out (optional) an existing Array to use.
     * If this is omitted, a new Array will be created.
     *
     * @return an Array containing the Movie's layer names
     */
    public function getLayerNames (out :Array = null) :Array {
        if (out == null) {
            out = [];
        } else {
            out.length = 0;
        }

        for each (var layer :Layer in _layers) {
            out[out.length] = layer.name;
        }

        return out;
    }

    /**
     * @private
     *
     * Helper function for goTo(). Saves us from calling extractFrame() multiple times.
     */
    protected function goToInternal (requestedFrame :int, recursive :Boolean) :Movie {
        if (_isUpdatingFrame) {
            _pendingGoToFrame = requestedFrame;

        } else {
            var ourFrame :int = requestedFrame;
            if (ourFrame >= _numFrames) {
                ourFrame = _numFrames;
            }
            _playTime = ourFrame / _frameRate;
            updateFrame(ourFrame, 0);

            if (recursive) {
                for each (var layer :Layer in _layers) {
                    var childMovie :Movie = (layer._currentDisplay as Movie);
                    if (childMovie != null) {
                        childMovie.goToInternal(requestedFrame, recursive);
                    }
                }
            }
        }
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
        if (dt < 0) {
            throw new Error("Invalid time [dt=" + dt + "]");
        }

        if (_skipAdvanceTime) {
            _skipAdvanceTime = false;
            return;
        }

        if (_state == STOPPED) {
            return;
        }

        if (_state == PLAYING && _numFrames > 1) {
            _playTime += dt;
            var actualPlaytime :Number = _playTime;
            if (_playTime >= _duration) {
                _playTime %= _duration;
            }

            // If _playTime is very close to _duration, rounding error can cause us to
            // land on lastFrame + 1. Protect against that.
            var newFrame :int = int(_playTime * _frameRate);
            if (newFrame < 0) {
                newFrame = 0;
            } else if (newFrame >= _numFrames) {
                newFrame = _numFrames - 1;
            }

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
            var childMovie :Movie = (layer._currentDisplay as Movie);
            if (childMovie != null) {
                childMovie.advanceTime(dt);
            }
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
            // Ensure that the layer has been fiddled with. If someone has reparented
            // the layer's currentDisplay, we can't get its bounds without running
            // the risk of an exception being thrown.
            // TODO: emit a warning in this circumstance?
            if (layer._currentDisplay.parent == this) {
                layer.expandBounds(targetSpace, resultRect);
            }
        }

        // if no contents exist, simply include this movie's position in the bounds
        if (resultRect.isEmpty()) {
            getTransformationMatrix(targetSpace, IDENTITY_MATRIX);
            MatrixUtil.transformCoords(IDENTITY_MATRIX, 0.0, 0.0, HELPER_POINT);
            resultRect.setTo(HELPER_POINT.x, HELPER_POINT.y, 0, 0);
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

    internal function setParentMovie (movie :Movie) :void {
        _isManagedByParentMovie = true;
    }

    /** @private */
    protected function extractFrame (position :Object) :int {
        if (position is int) {
            return int(position);
        } else if (position is String) {
            const label :String = String(position);
            var frame :int = getFrameForLabel(label);
            if (frame < 0) {
                throw new Error("No such label '" + label + "'");
            }
            return frame;
        } else {
            throw new Error("Movie position must be an int frame or String label");
        }
    }

    /**
     * @private
     *
     * Fires label signals and updates layers for the given frame.
     * We don't handle updating any child movies in this function - child moving updating
     * is handled in advanceTime() and goTo(), both of which call updateFrame().
     *
     * @param dt the timeline's elapsed time since the last update. This should be 0
     * for updates that are the result of a "goTo" call.
     */
    protected function updateFrame (newFrame :int, dt :Number) :void {
        if (newFrame < 0 || newFrame >= _numFrames) {
            throw new Error("Invalid frame [frame=" + newFrame + ", validRange=0-" + (_numFrames - 1) + "]");
        }

        if (_isUpdatingFrame) {
            // This should never happen.
            // (goTo() should set _pendingGoToFrame if _isUpdatingFrame == true)
            throw new Error("updateFrame called recursively");
        }

        _pendingGoToFrame = NO_FRAME;
        _isUpdatingFrame = true;

        // Update the frame before firing frame label signals, so if firing changes the frame,
        // it sticks.
        const prevFrame :int = _frame;
        _frame = newFrame;

        // determine which labels to fire signals for
        var startFrame :int;
        var frameCount :int;
        if (dt <= 0) {
            // if dt <= 0, we're here because of a goTo
            startFrame = newFrame;
            frameCount = 1;
        } else {
            startFrame = (prevFrame + 1 < _numFrames ? prevFrame + 1 : 0);
            frameCount = (_frame - prevFrame);
            if ((dt >= _duration) || (newFrame < _frame)) {
                // we wrapped
                frameCount += _numFrames;
            }
        }

        // Fire signals. Stop if pendingFrame is updated, which indicates that the client
        // has called goTo()
        var frameIdx :int = startFrame;
        for (var ii :int = 0; ii < frameCount; ++ii) {
            if (_pendingGoToFrame != NO_FRAME) {
                break;
            }

            if (_labels[frameIdx] != null) {
                for each (var label :String in _labels[frameIdx]) {
                    this.labelPassed.emit(label);
                    if (_pendingGoToFrame != NO_FRAME) {
                        break;
                    }
                }
            }

            // avoid modulo division by updating frameIdx each time through the loop
            if (++frameIdx == _numFrames) {
                frameIdx = 0;
            }
        }

        _isUpdatingFrame = false;

        // If we were interrupted by a goTo(), go to that frame now.
        // Otherwise, draw our new frame.
        if (_pendingGoToFrame != NO_FRAME) {
            var pending :int = _pendingGoToFrame;
            _pendingGoToFrame = NO_FRAME;
            goTo(pending);

        } else if (newFrame != prevFrame) {
            for each (var layer :Layer in _layers) {
                layer.drawFrame(newFrame);
            }
        }
    }

    protected function createLayer (movie :Movie, src :LayerMold, library :Library, flipbook :Boolean) :Layer {
        return new Layer(movie, src, library, flipbook);
    }

    protected var _isUpdatingFrame :Boolean;
    protected var _pendingGoToFrame :int = NO_FRAME;
    protected var _frame :int = NO_FRAME, _stopFrame :int = NO_FRAME;
    protected var _state :String = PLAYING;
    protected var _playTime :Number = 0;
    protected var _duration :Number;
    protected var _layers :Vector.<Layer>;
    protected var _numFrames :int;
    protected var _frameRate :Number;
    protected var _labels :Vector.<Vector.<String>>;
    private var _skipAdvanceTime :Boolean = false;
    internal var _playerData :MoviePlayerNode;
    private var _isManagedByParentMovie :Boolean;

    private static const HELPER_POINT :Point = new Point();
    private static const IDENTITY_MATRIX :Matrix = new Matrix();

    private static const NO_FRAME :int = -1;

    private static const STOPPED :String = "STOPPED";
    private static const PLAYING_CHILDREN_ONLY :String = "PLAYING_CHILDREN_ONLY";
    private static const PLAYING :String = "PLAYING";
}
}

