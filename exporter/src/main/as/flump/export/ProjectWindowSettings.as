//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flump.export.ProjectController;

import com.threerings.util.Preconditions;

public class ProjectWindowSettings
{
    public var configFilePath :String;
    public var windowX :Number;
    public var windowY :Number;

    public static function fromProject (ctrl :ProjectController) :ProjectWindowSettings {
        Preconditions.checkArgument(ctrl.configFile != null, "Project hasn't been saved!");
        var settings :ProjectWindowSettings = new ProjectWindowSettings();
        settings.configFilePath = ctrl.configFile.nativePath;
        settings.windowX = ctrl.win.nativeWindow.x;
        settings.windowY = ctrl.win.nativeWindow.y;
        return settings;
    }

    public static function fromObject (obj :Object) :ProjectWindowSettings {
        var settings :ProjectWindowSettings = new ProjectWindowSettings();
        settings.configFilePath = obj.configFilePath;
        settings.windowX = obj.windowX;
        settings.windowY = obj.windowY;
        return settings;
    }
}
}
