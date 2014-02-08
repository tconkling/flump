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

import flash.text.AntiAliasType;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.text.TextFormatAlign;

public class TextFieldBuilder
{
    /**
     * Creates the TextField
     */
    public function build () :TextField
    {
        return TextFieldUtil.createField(_text, _initProps, _formatProps);
    }

    /// Init Props

    /**
     * When set to true and the text field is not in focus, Flash Player highlights
     * the selection in the text field in gray. When set to false and the text field is not
     * in focus, Flash Player does not highlight the selection in the text field.
     *
     * The default value is false.
     */
    public function alwaysShowSelection (val :Boolean) :TextFieldBuilder
    {
        _initProps.alwaysShowSelection = val;
        return this;
    }

    /**
     * The type of anti-aliasing used for this text field. Use flash.text.AntiAliasType
     * constants for this property. You can control this setting only if the font is
     * embedded (with the embedFonts property set to true). The default setting is
     * flash.text.AntiAliasType.NORMAL.
     */
    public function antiAliasType (type :String) :TextFieldBuilder
    {
        _initProps.antiAliasType = type;
        return this;
    }

    /**
     * Equivalent to antiAliasType(AntiAliasType.ADVANCED)
     */
    public function antiAliasTypeAdvanced () :TextFieldBuilder
    {
        return antiAliasType(AntiAliasType.ADVANCED);
    }

    /**
     * Equivalent to antiAliasType(AntiAliasType.NORMAL)
     */
    public function antiAliasTypeNormal () :TextFieldBuilder
    {
        return antiAliasType(AntiAliasType.NORMAL);
    }

    /**
     * Controls automatic sizing and alignment of text fields. Acceptable values for the
     * TextFieldAutoSize constants: TextFieldAutoSize.NONE (the default), TextFieldAutoSize.LEFT,
     * TextFieldAutoSize.RIGHT, and TextFieldAutoSize.CENTER.
     *
     * If autoSize is set to TextFieldAutoSize.NONE (the default) no resizing occurs.
     *
     * If autoSize is set to TextFieldAutoSize.LEFT, the text is treated as left-justified text,
     * meaning that the left margin of the text field remains fixed and any resizing of a single
     * line of the text field is on the right margin. If the text includes a line break
     * (for example, "\n" or "\r"), the bottom is also resized to fit the next line of text.
     * If wordWrap is also set to true, only the bottom of the text field is resized and
     * the right side remains fixed.
     *
     * If autoSize is set to TextFieldAutoSize.RIGHT, the text is treated as right-justified text,
     * meaning that the right margin of the text field remains fixed and any resizing of a single
     * line of the text field is on the left margin. If the text includes a line break
     * (for example, "\n" or "\r"), the bottom is also resized to fit the next line of text.
     * If wordWrap is also set to true, only the bottom of the text field is resized and the
     * left side remains fixed.
     *
     * If autoSize is set to TextFieldAutoSize.CENTER, the text is treated as
     * center-justified text, meaning that any resizing of a single line of the text
     * field is equally distributed to both the right and left margins. If the text includes a
     * line break (for example, "\n" or "\r"), the bottom is also resized to fit the next line of
     * text. If wordWrap is also set to true, only the bottom of the text field is resized and the
     * left and right sides remain fixed.
     */
    public function autoSize (type :String) :TextFieldBuilder
    {
        _initProps.autoSize = type;
        return this;
    }

    /**
     * Equivalent to autoSize(TextFieldAutoSize.NONE)
     */
    public function autoSizeNone () :TextFieldBuilder
    {
        return autoSize(TextFieldAutoSize.NONE);
    }

    /**
     * Equivalent to autoSize(TextFieldAutoSize.LEFT)
     */
    public function autoSizeLeft () :TextFieldBuilder
    {
        return autoSize(TextFieldAutoSize.LEFT);
    }

    /**
     * Equivalent to autoSize(TextFieldAutoSize.CENTER)
     */
    public function autoSizeCenter () :TextFieldBuilder
    {
        return autoSize(TextFieldAutoSize.CENTER);
    }

    /**
     * Equivalent to autoSize(TextFieldAutoSize.RIGHT)
     */
    public function autoSizeRight () :TextFieldBuilder
    {
        return autoSize(TextFieldAutoSize.RIGHT);
    }

    /**
     * The color of the text field background. The default value is 0xFFFFFF (white).
     * Also causes the 'background' property to be set to true.
     */
    public function backgroundColor (val :uint) :TextFieldBuilder
    {
        _initProps.backgroundColor = val;
        _initProps.background = true;
        return this;
    }

    /**
     * The color of the text field border. The default value is 0xFFFFFF (white).
     * Also causes the 'border' property to be set to true.
     */
    public function borderColor (val :uint) :TextFieldBuilder
    {
        _initProps.borderColor = val;
        _initProps.border = true;
        return this;
    }

    /**
     * Specifies whether the text field is a password text field. If the value of
     * this property is true, the text field is treated as a password text field and hides the
     * input characters using asterisks instead of the actual characters. If false, the
     * text field is not treated as a password text field. When password mode is enabled,
     * the Cut and Copy commands and their corresponding keyboard shortcuts will not function.
     * This security mechanism prevents an unscrupulous user from using the shortcuts to discover
     * a password on an unattended computer.
     *
     * The default value is false.
     */
    public function displayAsPassword (val :Boolean) :TextFieldBuilder
    {
        _initProps.displayAsPassword = val;
        return this;
    }

    /**
     * Specifies whether to render by using embedded font outlines. If false,
     * Flash Player renders the text field by using device fonts.
     *
     * If you set the embedFonts property to true for a text field, you must specify a font
     * for that text by using the font property of a TextFormat object applied to the text field.
     * If the specified font is not embedded in the SWF file, the text is not displayed.
     *
     * The default value is false.
     */
    public function embedFonts (val :Boolean) :TextFieldBuilder
    {
        _initProps.embedFonts = val;
        return this;
    }

    /**
     * Sets the HTML representation of the TextField contents.
     */
    public function htmlText (val :String) :TextFieldBuilder
    {
        _initProps.htmlText = val;
        return this;
    }


    /**
     * A Boolean value that indicates whether Flash Player automatically scrolls multiline text
     * fields when the user clicks a text field and rolls the mouse wheel.
     * By default, this value is true. This property is useful if you want to prevent
     * mouse wheel scrolling of text fields, or implement your own text field scrolling.
     */
    public function mouseWheelEnabled (val :Boolean) :TextFieldBuilder
    {
        _initProps.mouseWheelEnabled = val;
        return this;
    }

    /**
     * Specifies whether this object receives mouse, or other user input, messages.
     * The default value is true.
     * If set to false, the 'selectable' property of the TextField will also be false.
     */
    public function mouseEnabled (enabled :Boolean) :TextFieldBuilder
    {
        _initProps.mouseEnabled = enabled;
        if (!enabled) {
            selectable(false);
        }
        return this;
    }

    /**
     * Indicates whether field is a multiline text field. If the value is true, the text field
     * is multiline; if the value is false, the text field is a single-line text field.
     * In a field of type TextFieldType.INPUT, the multiline value determines whether the
     * Enter key creates a new line (a value of false, and the Enter key is ignored).
     * If you paste text into a TextField with a multiline value of false, newlines are stripped
     * out of the text.
     */
    public function multiline (val :Boolean) :TextFieldBuilder
    {
        _initProps.multiline = val;
        return this;
    }

    /**
     * Attaches a GlowFilter to the TextField.
     */
    public function outline (color :uint, width :Number = 2,
        strength :Number = 255) :TextFieldBuilder
    {
        _initProps.outlineColor = color;
        _initProps.outlineWidth = width;
        _initProps.outlineStrength = strength;
        return this;
    }

    /**
     * A Boolean value that indicates whether the text field is selectable. The value true
     * indicates that the text is selectable. The selectable property controls whether a text
     * field is selectable, not whether a text field is editable. A dynamic text field can be
     * selectable even if it is not editable. If a dynamic text field is not selectable, the user
     * cannot select its text.
     *
     * If selectable is set to false, the text in the text field does not respond to selection
     * commands from the mouse or keyboard, and the text cannot be copied with the Copy command.
     * If selectable is set to true, the text in the text field can be selected with the mouse or
     * keyboard, and the text can be copied with the Copy command. You can select text this way
     * even if the text field is a dynamic text field instead of an input text field.
     */
    public function selectable (val :Boolean) :TextFieldBuilder
    {
        _initProps.selectable = val;
        return this;
    }

    /**
     * A string that is the current text in the text field. Lines are separated by the
     * carriage return character ('\r', ASCII 13). This property contains unformatted text in
     * the text field, without HTML tags.
     *
     * To get the text in HTML form, use the htmlText property.
     */
    public function text (val :String) :TextFieldBuilder
    {
        _text = val;
        return this;
    }

    /**
     * The type of the text field. Either one of the following TextFieldType constants:
     * TextFieldType.DYNAMIC, which specifies a dynamic text field, which a user cannot edit,
     * or TextFieldType.INPUT, which specifies an input text field, which a user can edit.
     *
     * The default value is dynamic.
     */
    public function type (val :String) :TextFieldBuilder
    {
        _initProps.type = val;
        return this;
    }

    /**
     * Makes an uneditable text field. This is the default.
     * Equivalent to type(TextFieldType.DYNAMIC)
     */
    public function typeDynamic () :TextFieldBuilder
    {
        return type(TextFieldType.DYNAMIC);
    }

    /**
     * Makes an editable text field. Equivalent to type(TextFieldType.INPUT)
     */
    public function typeInput () :TextFieldBuilder
    {
        return type(TextFieldType.INPUT);
    }

    /**
     * A Boolean value that indicates whether the text field has word wrap.
     * If the value of wordWrap is true, the text field has word wrap; if the value is false,
     * the text field does not have word wrap. The default value is false.
     */
    public function wordWrap (val :Boolean) :TextFieldBuilder
    {
        _initProps.wordWrap = val;
        return this;
    }

    /**
     * The width of the TextField.
     */
    public function width (val :Number) :TextFieldBuilder
    {
        _initProps.width = val;
        return this;
    }

    /// Format Props

    /**
     * Indicates the alignment of the paragraph. Valid values are TextFormatAlign constants.
     */
    public function align (type :String) :TextFieldBuilder
    {
        _formatProps.align = type;
        return this;
    }

    /**
     * Equivalent to align(TextFormatAlign.LEFT)
     */
    public function alignLeft () :TextFieldBuilder
    {
        return align(TextFormatAlign.LEFT);
    }

    /**
     * Equivalent to align(TextFormatAlign.CENTER)
     */
    public function alignCenter () :TextFieldBuilder
    {
        return align(TextFormatAlign.CENTER);
    }

    /**
     * Equivalent to align(TextFormatAlign.RIGHT)
     */
    public function alignRight () :TextFieldBuilder
    {
        return align(TextFormatAlign.RIGHT);
    }

    /**
     * Equivalent to align(TextFormatAlign.JUSTIFY)
     */
    public function alignJustify () :TextFieldBuilder
    {
        return align(TextFormatAlign.JUSTIFY);
    }

    /**
     * Indicates the block indentation in pixels. Block indentation is applied to an
     * entire block of text; that is, to all lines of the text. In contrast,
     * normal indentation (TextFormat.indent) affects only the first line of each paragraph.
     * If this property is null, the TextFormat object does not specify block indentation
     * (block indentation is 0)
     */
    public function blockIndent (val :Number) :TextFieldBuilder
    {
        _formatProps.blockIndent = val;
        return this;
    }

    /**
     * Specifies whether the text is boldface. The default value is null, which
     * means no boldface is used. If the value is true, then the text is boldface.
     */
    public function bold (val :Boolean=true) :TextFieldBuilder
    {
        _formatProps.bold = val;
        return this;
    }

    /**
     * Indicates that the text is part of a bulleted list. In a bulleted list,
     * each paragraph of text is indented. To the left of the first line of each paragraph,
     * a bullet symbol is displayed. The default value is null, which means no
     * bulleted list is used.
     */
    public function bullet (val :Boolean) :TextFieldBuilder
    {
        _formatProps.bullet = val;
        return this;
    }

    /**
     * Indicates the color of the text. A number containing three 8-bit RGB components;
     * for example, 0xFF0000 is red, and 0x00FF00 is green. The default value is null,
     * which means that Flash Player uses the color black (0x000000).
     */
    public function color (val :uint) :TextFieldBuilder
    {
        _formatProps.color = val;
        return this;
    }

    /**
     * The name of the font for text in this text format, as a string.
     * The default value is null, which means that Flash Player uses
     * Times New Roman font for the text.
     */
    public function font (name :String) :TextFieldBuilder
    {
        var isBuiltInFont :Boolean =
            (name == "_sans" || name == "_serif" || name == "_typewriter");
        _formatProps.font = name;

        // If this is not set to true, modifying the TextField's alpha won't work
        // But it cannot be set to true if we're using the built-in fonts
        _initProps.embedFonts = !isBuiltInFont;

        return this;
    }

    /**
     * Indicates the indentation from the left margin to the first character in the paragraph.
     * The default value is null, which indicates that no indentation is used.
     */
    public function indent (val :Number) :TextFieldBuilder
    {
        _formatProps.indent = val;
        return this;
    }

    /**
     * ndicates whether text in this text format is italicized.
     * The default value is null, which means no italics are used.
     */
    public function italic (val :Boolean) :TextFieldBuilder
    {
        _formatProps.italic = val;
        return this;
    }

    /**
     * A Boolean value that indicates whether kerning is enabled (true) or disabled (false).
     * Kerning adjusts the pixels between certain character pairs to improve readability, and
     * should be used only when necessary, such as with headings in large fonts.
     * Kerning is supported for embedded fonts only.
     *
     * Certain fonts such as Verdana and monospaced fonts, such as Courier New,
     * do not support kerning.
     *
     * The default value is null, which means that kerning is not enabled.
     */
    public function kerning (val :Boolean) :TextFieldBuilder
    {
        _formatProps.kerning = val;
        return this;
    }

    /**
     * An integer representing the amount of vertical space (called leading) between lines.
     * The default value is null, which indicates that the amount of leading used is 0.
     */
    public function leading (val :int) :TextFieldBuilder
    {
        _formatProps.leading = val;
        return this;
    }

    /**
     * The left margin of the paragraph, in pixels.
     * The default value is null, which indicates that the left margin is 0 pixels.
     */
    public function leftMargin (val :Number) :TextFieldBuilder
    {
        _formatProps.leftMargin = val;
        return this;
    }

    /**
     * A number representing the amount of space that is uniformly distributed between all
     * characters. The value specifies the number of pixels that are added to the advance after
     * each character. The default value is null, which means that 0 pixels of letter spacing
     * is used. You can use decimal values such as 1.75.
     */
    public function letterSpacing (val :Number) :TextFieldBuilder
    {
        _formatProps.letterSpacing = val;
        return this;
    }

    /**
     * The right margin of the paragraph, in pixels.
     * The default value is null, which indicates that the right margin is 0 pixels.
     */
    public function rightMargin (val :Number) :TextFieldBuilder
    {
        _formatProps.rightMargin = val;
        return this;
    }

    /**
     * The size in pixels of text in this text format.
     * The default value is null, which means that a size of 12 is used.
     */
    public function size (val :int) :TextFieldBuilder
    {
        _formatProps.size = val;
        return this;
    }

    /**
     * Specifies custom tab stops as an array of non-negative integers. Each tab stop is
     * specified in pixels. If custom tab stops are not specified (null), the default tab stop
     * is 4 (average character width).
     */
    public function tabStops (val :Array) :TextFieldBuilder
    {
        _formatProps.tabStops = val;
        return this;
    }

    /**
     * Indicates the target window where the hyperlink is displayed. If the target window is
     * an empty string, the text is displayed in the default target window _self. You can
     * choose a custom name or one of the following four names: _self specifies the current
     * frame in the current window, _blank specifies a new window, _parent specifies the
     * parent of the current frame, and _top specifies the top-level frame in the current
     * window. If the TextFormat.url property is an empty string or null, you can get or set
     * this property, but the property will have no effect.
     */
    public function target (val :String) :TextFieldBuilder
    {
        _formatProps.target = val;
        return this;
    }

    /**
     * Indicates whether the text that uses this text format is underlined (true) or not (false).
     * This underlining is similar to that produced by the &lt;U&gt; tag, but the latter is not
     * true underlining, because it does not skip descenders correctly. The default value is null,
     * which indicates that underlining is not used.
     */
    public function underline (val :Boolean) :TextFieldBuilder
    {
        _formatProps.underline = val;
        return this;
    }

    /**
     * Indicates the target URL for the text in this text format. If the url property is an
     * empty string, the text does not have a hyperlink. The default value is null, which
     * indicates that the text does not have a hyperlink.
     *
     * Note: The text with the assigned text format must be set with the htmlText property
     * for the hyperlink to work.
     */
    public function url (val :String) :TextFieldBuilder
    {
        _formatProps.url = val;
        return this;
    }

    protected var _text :String = "";
    protected var _initProps :Object = {};
    protected var _formatProps :Object = {};
}


}
