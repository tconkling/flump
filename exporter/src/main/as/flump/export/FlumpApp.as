//
// flump-exporter

package flump.export {

import com.threerings.util.Arrays;
import com.threerings.util.F;
import com.threerings.util.Log;
import com.threerings.util.Map;
import com.threerings.util.Maps;

import flash.desktop.InvokeEventReason;
import flash.desktop.NativeApplication;
import flash.display.NativeWindow;
import flash.events.Event;
import flash.events.InvokeEvent;
import flash.filesystem.File;

import flump.xfl.XflLibrary;

import spark.components.Window;

import starling.display.Sprite;

public class FlumpApp
{
    public static const NA :NativeApplication = NativeApplication.nativeApplication;

    public static function get app () :FlumpApp {
        return _app;
    }

    public function FlumpApp () {
        if (_app != null) {
            throw new Error("FlumpApp is a singleton");
        }
        _app = this;
    }

    public function run () :void {
        Log.setLevel("", Log.INFO);

        var launched :Boolean = false;
        NA.addEventListener(InvokeEvent.INVOKE, function (event :InvokeEvent) :void {
            if (event.arguments.length > 0) {
                // A project file has been double-clicked. Open it.
                openProject(new File(event.arguments[0]));

            } else if (!launched) {
                // The app has been launched directly. Open the last-opened project if
                // it exists; else open a new project.
                openProject(FlumpSettings.hasConfigFilePath ?
                    new File(FlumpSettings.configFilePath) : null);
            } else if (_projects.length == 0) {
                // The app has been resumed. We have no open projects; create a new one.
                openProject();
            }

            launched = true;
        });
    }

    public function showPreviewWindow (lib :XflLibrary) :void {
        if (_previewController == null || _previewWindow.closed || _previewControls.closed) {
            _previewWindow = new PreviewWindow();
            _previewControls = new PreviewControlsWindow();
            _previewWindow.started = function (container :Sprite) :void {
                _previewController = new PreviewController(lib, container, _previewWindow,
                    _previewControls);
            }

            _previewWindow.open();
            _previewControls.open();

            preventWindowClose(_previewWindow.nativeWindow);
            preventWindowClose(_previewControls.nativeWindow);

        } else {
            _previewController.lib = lib;
            _previewControls.activate();
            _previewWindow.activate();
        }

        _previewWindow.orderToFront();
        _previewControls.orderToFront();
    }

    public function openProject (configFile :File = null) :void {
        // This project may already be open.
        for each (var ctrl :ProjectController in _projects) {
            if (ctrl.configFile != null && ctrl.configFile.nativePath == configFile.nativePath) {
                ctrl.win.activate();
                return;
            }
        }

        var controller :ProjectController = new ProjectController(configFile);
        controller.win.addEventListener(Event.CLOSE, F.callbackOnce(closeProject, controller));
        _projects.push(controller);
    }

    protected function closeProject (controller :ProjectController) :void {
        Arrays.removeFirst(_projects, controller);
    }

    // Causes a window to be hidden, rather than closed, when its close box is clicked
    protected static function preventWindowClose (window :NativeWindow) :void {
        window.addEventListener(Event.CLOSING, function (e :Event) :void {
            e.preventDefault();
            window.visible = false;
        });
    }

    protected var _projects :Array = [];

    protected var _previewController :PreviewController;
    protected var _previewWindow :PreviewWindow;
    protected var _previewControls :PreviewControlsWindow;

    protected static var _app :FlumpApp;
}
}
