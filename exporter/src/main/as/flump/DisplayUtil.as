//
// Flump - Copyright 2013 Flump Authors

package flump {

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;

public class DisplayUtil
{
    /**
     * Call <code>callback</code> for <code>disp</code> and all its descendants.
     *
     * This is nearly exactly like mx.utils.DisplayUtil.walkDisplayObjects,
     * except this method copes with security errors when examining a child.
     * @param disp the root of the hierarchy at which to start the iteration
     * @param callback function to call for each node in the display tree for disp. The passed
     * object will never be null and the function will be called exactly once for each node, unless
     * iteration is halted. The callback can have one of four signatures:
     * <listing version="3.0">
     *     function callback (disp :DisplayObject) :void
     *     function callback (disp :DisplayObject) :Boolean
     *     function callback (disp :DisplayObject, depth :int) :void
     *     function callback (disp :DisplayObject, depth :int) :Boolean
     * </listing>
     *
     * If <code>callback</code> returns <code>true</code>, traversal will halt.
     *
     * The passed in depth is 0 for <code>disp</code>, and increases by 1 for each level of
     * children.
     *
     * @return <code>true</code> if <code>callback</code> returned <code>true</code>
     */
    public static function applyToHierarchy (
        root :DisplayObject, callback :Function, securityErrorCallback :Function=null,
        maxDepth :int=int.MAX_VALUE) :Boolean
    {
        var toApply :Function = callback;
        // Earlier versions of this function didn't pass a depth to callback, so don't
        // assume that. Since we know we're getting a function of length 1 or 2, adapt manually
        // instead of using F.
        if (callback.length == 1) {
            toApply = function (disp :DisplayObject, depth :int) :Boolean {
                return callback(disp);
            }
        }
        return applyToHierarchy0(root, maxDepth, toApply, securityErrorCallback, 0);
    }

    /** Helper for applyToHierarchy */
    protected static function applyToHierarchy0 (root :DisplayObject, maxDepth :int,
        callback :Function, securityErrorCallback :Function, depth :int) :Boolean
    {
        // halt traversal if callbackFunction returns true
        if (Boolean(callback(root, depth))) {
            return true;
        }

        if (++depth > maxDepth || !(root is DisplayObjectContainer)) {
            return false;
        }
        var container :DisplayObjectContainer = DisplayObjectContainer(root);
        var nn :int = container.numChildren;
        for (var ii :int = 0; ii < nn; ii++) {
            var child :DisplayObject;
            try {
                child = container.getChildAt(ii);
            } catch (err :SecurityError) {
                if (securityErrorCallback != null) {
                    securityErrorCallback(err, depth);
                }
                continue;
            }
            if (applyToHierarchy0(child, maxDepth, callback, securityErrorCallback, depth)) {
                return true;
            }
        }

        return false;
    }
}
}
