//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.events.Event;
import flash.events.MouseEvent;
import flash.filesystem.File;
import flash.net.SharedObject;

import mx.controls.FileSystemComboBox;

import org.osflash.signals.Signal;

import spark.components.Button;
import spark.events.IndexChangeEvent;

import com.threerings.util.F;

public class DirChooser
{
    public const changed :Signal = new Signal(File);

    public function DirChooser (settings :SharedObject, settingKey :String, selector :FileSystemComboBox, button :Button)
    {
        function setDir (root :File) :void {
            if (_dir == root.nativePath) return;
            _dir = root.nativePath;
            settings.data[settingKey] = _dir;
            settings.flush();
            selector.directory = root;
            changed.dispatch(root);
        }
        setDir(new File(settings.data[settingKey] || File.documentsDirectory.nativePath));
        button.addEventListener(MouseEvent.CLICK, function (..._) :void {
            // Use a new File object to browse on as browseForDirectory modifies the object it uses
            const browser :File = new File(dir);
            browser.addEventListener(Event.SELECT, F.callback(setDir, browser));
            browser.browseForDirectory("Select Directory")
        });
        selector.addEventListener(IndexChangeEvent.CHANGE, function (..._) :void {
            setDir(selector.directory);
        });
    }

    public function get dir () :String { return _dir; }

    protected var _dir :String;
}
}
