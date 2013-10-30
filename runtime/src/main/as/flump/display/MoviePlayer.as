//
// flump

package flump.display {

import starling.animation.IAnimatable;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.events.Event;

/**
 * A utility for automatically playing Movies.
 *
 * MoviePlayer automatically tracks all Movies that are added to the display list. Calling
 * MoviePlayer.advanceTime will update all Movies.
 *
 * MoviePlayer can be added to a Juggler to automate the call to advanceTime.
 */
public class MoviePlayer
    implements IAnimatable
{
    public function MoviePlayer (root :DisplayObjectContainer) {
        _displayRoot = root;
        _displayRoot.addEventListener(Event.ADDED, onAdded);
        _displayRoot.addEventListener(Event.REMOVED, onRemoved);
    }

    public function advanceTime (dt :Number) :void {
        var cur :MoviePlayerNode = _head;
        while (cur != null) {
            cur.movie.advanceTime(dt);
            cur = cur.next;
        }
    }

    public function dispose () :void {
        _displayRoot.removeEventListener(Event.ADDED, onAdded);
        _displayRoot.removeEventListener(Event.REMOVED, onRemoved);

        var cur :MoviePlayerNode = _head;
        while (cur != null) {
            cur.movie._playerData = null;
            cur = cur.next;
        }
        _head = null;
    }

    protected function onAdded (e :Event) :void {
        addMovies(e.target as DisplayObject);
    }

    protected function onRemoved (e :Event) :void {
        removeMovies(e.target as DisplayObject);
    }

    protected function addMovies (disp :DisplayObject) :void {
        var movie :Movie = disp as Movie;
        if (movie != null) {
            // Add this movie to our list if it's not already in a MoviePlayer, and if its
            // parent isn't a Movie (parent Movies control their children).
            if (!(movie.parent is Movie) && movie._playerData == null) {
                var node :MoviePlayerNode = new MoviePlayerNode(movie, this);
                movie._playerData = node;

                // link
                if (_head != null) {
                    node.next = _head;
                    _head.prev = node;
                }
                _head = node;
            }

            // Stop searching when we find our first Movie; Movies update their children, so
            // we only track top-level movies.
            return;
        }

        var container :DisplayObjectContainer = (disp as DisplayObjectContainer);
        if (container != null) {
            for (var ii :int = container.numChildren - 1; ii >= 0; --ii) {
                addMovies(container.getChildAt(ii));
            }
        }
    }

    protected function removeMovies (disp :DisplayObject) :void {
        var movie :Movie = disp as Movie;
        if (movie != null) {
            if (movie._playerData != null && movie._playerData.player == this) {
                var node :MoviePlayerNode = movie._playerData;
                movie._playerData = null;

                // unlink the movie
                var next :MoviePlayerNode = node.next;
                var prev :MoviePlayerNode = node.prev;

                if (prev != null) {
                    prev.next = next;
                } else {
                    // If prev was null, node is the head of the list
                    if (_head != node) {
                        throw new Error("Movie list is broken, somehow");
                    }
                    _head = next;
                }

                if (next != null) {
                    next.prev = prev;
                }
            }

            return;
        }

        var container :DisplayObjectContainer = (disp as DisplayObjectContainer);
        if (container != null) {
            for (var ii :int = container.numChildren - 1; ii >= 0; --ii) {
                removeMovies(container.getChildAt(ii));
            }
        }
    }

    protected var _displayRoot :DisplayObjectContainer;
    protected var _head :MoviePlayerNode;
}
}
