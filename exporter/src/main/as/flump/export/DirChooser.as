//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.events.Event;
import flash.events.MouseEvent;
import flash.filesystem.File;

import org.osflash.signals.Signal;

import spark.components.Button;
import spark.components.Label;

import com.threerings.util.F;

public class DirChooser
{
    public const changed :Signal = new Signal(File);

    public function DirChooser (initial :File, selector :Label, button :Button)
    {
        function setDir (root :File) :void {
            if (_dir == root.nativePath) return;
            _dir = root.nativePath;
            selector.text = _dir;
            changed.dispatch(root);
        }
        if (initial != null && initial.exists) setDir(initial);
        else selector.text = "Unset";
        button.addEventListener(MouseEvent.CLICK, function (..._) :void {
            // Use a new File object to browse on as browseForDirectory modifies the object it uses
            var browser :File = dir;
            if (dir == null) browser = File.documentsDirectory;
            browser.addEventListener(Event.SELECT, F.callback(setDir, browser));
            browser.browseForDirectory("Select Directory");
        });
    }

    /** The selected directory or null if none has been selected. */
    public function get dir () :File { return _dir == null ? null : new File(_dir); }

    protected var _dir :String;
}
}
