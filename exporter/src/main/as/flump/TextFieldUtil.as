//
// aspirin library - Taking some of the pain out of Actionscript development.
// Copyright (C) 2007-2012 Three Rings Design, Inc., All Rights Reserved
// http://github.com/threerings/aspirin
//
// This library is free software; you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as published
// by the Free Software Foundation; either version 2.1 of the License, or
// (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

package flump {

import aspire.util.StringUtil;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.GlowFilter;
import flash.system.Capabilities;
import flash.system.System;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.utils.Dictionary;

public class TextFieldUtil
{
    /** A fudge factor that must be added to a TextField's textWidth when setting the width. */
    public static const WIDTH_PAD :int = 5;

    /** A fudge factor that must be added to a TextField's textHeight when setting the height. */
    public static const HEIGHT_PAD :int = 4;

    /**
     * Create a TextFieldBuilder for detailed specification of a TextField.
     *
     * @example
     * <listing version="3.0">
     * var tf :TextField = TextFieldUtil.newBuilder()
     *     .multiline(true)
     *     .wordWrap(true)
     *     .selectable(false)
     *     .autoSizeCenter()
     *     .alignCenter()
     *     .size(14)
     *     .text(text)
     *     .build();
     * </listing>
     */
    public static function newBuilder () :TextFieldBuilder
    {
        return new TextFieldBuilder();
    }

    /**
     * Ensures that a single-line TextField is not wider than the specified width, and
     * truncates it with the truncation string if is. If the TextField is truncated,
     * it will be resized to its new textWidth.
     *
     * @param width the maximum pixel width of the TextField. If tf.width > width,
     * the text inside the TextField will be truncated, and will have the truncation string
     * appended.
     * @param truncationString the string to append to the end of the TextField if it exceeds
     * the specified width.
     * @return true if truncation took place
     */
    public static function setMaximumTextWidth (
        tf :TextField, width :Number, truncationString :String = "...") :Boolean
    {
        if (tf.numLines > 1) {
            // We only operate on single-line TextFields
            return false;
        }

        // TextField.textWidth doesn't account for scale, so account for it here
        width /= tf.scaleX;

        var truncated :Boolean;
        var setText :String = tf.text;
        while (tf.textWidth + WIDTH_PAD > width && setText.length > 0) {
            // Drop characters from our string until we hit our target width.
            // Flash doesn't appear to provide a nicer way to get text metrics than
            // sticking stuff in a TextField and calling textWidth.
            setText = setText.substr(0, setText.length - 1);
            tf.text = setText + truncationString;

            truncated = true;
        }

        if (truncated) {
            // strip whitespace characters from the end of the truncated string
            setText = StringUtil.trimEnd(setText);
            tf.text = setText + truncationString;

            // resize the TextField
            tf.width = tf.textWidth + WIDTH_PAD;
            tf.height = tf.textHeight + HEIGHT_PAD;
        }

        return truncated;
    }

    /**
     * Create a TextField.
     * The field will have setFocusable() called on it.
     * Note that if the autoSize property is not none, then the field will be resized
     * to the size of the text, overwriting any width/height properties specified.
     *
     * @param initProps contains properties with which to initialize the TextField.
     * <br>Additionally it may contain the following properties:
     *    <br>outlineColor: uint,
     *    <br>outlineWidth: Number (default 2),
     *    <br>outlineStrength: Number (default 255)
     * @param formatProps contains properties with which to initialize the defaultTextFormat.
     */
    public static function createField (
        text :String, initProps :Object = null, formatProps :Object = null, clazz :Class = null)
        :TextField
    {
        var tf :TextField = (clazz == null) ? new TextField() : TextField(new clazz());

        if ((initProps != null) && ("outlineColor" in initProps)) {
            var blur :Number = Util.getDefault(initProps, "outlineWidth", 2) as Number;
            var strength :Number = Util.getDefault(initProps, "outlineStrength", 255) as Number;
            tf.filters = [ new GlowFilter(
                uint(initProps["outlineColor"]), 1, blur, blur, strength) ];
        }

        Util.init(tf, initProps, null, MASK_FIELD_PROPS);
        if (formatProps != null) {
            tf.defaultTextFormat = createFormat(formatProps);
        }
        updateText(tf, text);
        setFocusable(tf);

        return tf;
    }

    /**
     * Create a TextFormat using initProps.
     * If unspecified, the following properties have default values:
     *  size: 18
     *  font: _sans
     */
    public static function createFormat (initProps :Object) :TextFormat
    {
        var f :TextFormat = new TextFormat();
        Util.init(f, initProps, DEFAULT_FORMAT_PROPS);
        return f;
    }

    /**
     * Update the defaultTextFormat for the specified field, as well as all text therein.
     */
    public static function updateFormat (field :TextField, props :Object) :void
    {
        var f :TextFormat = field.defaultTextFormat; // this gets a clone of the default fmt
        Util.init(f, props); // update the clone
        field.defaultTextFormat = f; // set it as the new default
        updateText(field, field.text); // jiggle the text to update it
    }

    /**
     * Update the text in the field, automatically resizing it if appropriate.
     */
    public static function updateText (field :TextField, text :String) :void
    {
        field.text = text;
        if (field.autoSize != TextFieldAutoSize.NONE) {
            field.width = field.textWidth + WIDTH_PAD;
            field.height = field.textHeight + HEIGHT_PAD;
        }
    }

    /**
     * After the text is set and positioned, and any desired
     * adjustments have been made, this "bakes-in" the text size
     * into the TextField's width/height.
     */
    public static function sizeFieldToText (txt :TextField) :void
    {
        txt.autoSize = TextFieldAutoSize.NONE;
        // The WIDTH_PAD and HEIGHT_PAD values are hidden fudge factors needed to properly size
        // text fields to the size of the text in them. They're defined in
        // mx.controls.UITextField::mx_internal.TEXT_WIDTH_PADDING, but we'd prefer to not depend
        // on Flex in this library.
        txt.width = txt.textWidth + WIDTH_PAD;
        txt.height = txt.textHeight + HEIGHT_PAD;
    }

    /**
     * Add a special MouseEvent.CLICK listener so that the specified field is focusable
     * even inside a security boundary.
     */
    public static function setFocusable (field :TextField) :void
    {
        field.addEventListener(MouseEvent.CLICK, handleFieldFocus);
    }

    /**
     * Include the specified TextField in a set of TextFields in which only
     * one may have a selection at a time.
     */
    public static function trackSingleSelectable (textField :TextField) :void
    {
        textField.addEventListener(MouseEvent.MOUSE_MOVE, handleTrackedSelection);

        // immediately put the kibosh on any selection
        textField.setSelection(0, 0);
    }

    /**
     * Install listeners on the specified TextField such that the mouseEnabled property
     * is only true when the mouse is over a link.
     */
    public static function trackOnlyLinksMouseable (textField :TextField, on :Boolean = true) :void
    {
        if (on) {
            _mouseables[textField] = true;
            // always add the listener, seems easier than checking to see.
            _frameDispatcher.addEventListener(Event.ENTER_FRAME, handleTrackMouseable);

        } else {
            delete _mouseables[textField];
        }
    }

    /**
     * Internal method related to tracking a single selectable TextField.
     */
    protected static function handleTrackedSelection (event :MouseEvent) :void
    {
        if (event.buttonDown) {
            var field :TextField = event.target as TextField;
            if (field == _lastSelected) {
                updateSelection(field);

            } else if (field.selectionBeginIndex != field.selectionEndIndex) {
                // clear the last one..
                if (_lastSelected != null) {
                    handleLastSelectedRemoved();
                }
                _lastSelected = field;
                _lastSelected.addEventListener(Event.REMOVED_FROM_STAGE, handleLastSelectedRemoved);
                updateSelection(field);
            }
        }
    }

    /**
     * Checks every damn frame to see if we should make a TextField mouse-enabled.
     */
    protected static function handleTrackMouseable (event :Event) :void
    {
        var seen :Boolean = false;
        for (var f :* in _mouseables) {
            var field :TextField = f; // fucking hack of a language doesn't iterate non-string keys
            seen = true;
            if (field.stage != null) {
                var charIndex :int = field.getCharIndexAtPoint(field.mouseX, field.mouseY);
                field.mouseEnabled = (charIndex >= 0) && (charIndex < field.length) &&
                    !StringUtil.isBlank(field.getTextFormat(charIndex).url);
            }
        }
        if (!seen) {
            // try to remove the listener as soon as we can
            _frameDispatcher.removeEventListener(Event.ENTER_FRAME, handleTrackMouseable);
        }
    }

    /**
     * Process the selection.
     */
    protected static function updateSelection (field :TextField) :void
    {
        if (-1 != Capabilities.os.indexOf("Linux")) {
            var str :String = field.text.substring(
                field.selectionBeginIndex, field.selectionEndIndex);
            System.setClipboard(str);
        }
    }

    /**
     * Internal method related to tracking a single selectable TextField.
     */
    protected static function handleLastSelectedRemoved (... ignored) :void
    {
        _lastSelected.setSelection(0, 0);
        _lastSelected.removeEventListener(Event.REMOVED_FROM_STAGE, handleLastSelectedRemoved);
        _lastSelected = null;
    }

    /**
     * Handle focusing the text field.
     */
    protected static function handleFieldFocus (event :MouseEvent) :void
    {
        var tf :TextField = TextField(event.currentTarget);
        if (tf.stage.focus == tf) {
            return; // already has focus, bail.
        }

        // else, assign focus
        tf.stage.focus = tf;

        // try to be smart and move the cursor near the click
        if (tf.selectable) {
            var idx :int = tf.getCharIndexAtPoint(event.localX, event.localY);
            if (idx != -1) {
                tf.setSelection(idx, idx);
            }
        }
    }

    /** The last tracked TextField to be selected. */
    protected static var _lastSelected :TextField;

    protected static var _mouseables :Dictionary = new Dictionary(true); // weak keys

    protected static const _frameDispatcher :Sprite = new Sprite();

    protected static const MASK_FIELD_PROPS :Object = { outlineColor: true, outlineWidth: true,
        outlineStrength: true };

    protected static const DEFAULT_FORMAT_PROPS :Object = { size: 18, font: "_sans" };
}
}
