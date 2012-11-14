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
import flash.events.Event;
import flash.events.InvokeEvent;
import flash.filesystem.File;

import spark.components.Window;

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

    protected var _projects :Array = [];

    protected static var _app :FlumpApp;
}
}
