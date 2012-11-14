//
// flump-exporter

package flump.export {

import flash.filesystem.File;

public class FlumpApp
{
    public function run () :void {
        var win :ProjectWindow = new ProjectWindow();
        win.open();

        _controller = new ProjectController(win,
            FlumpSettings.hasConfigFilePath ? new File(FlumpSettings.configFilePath) : null);
    }

    protected var _controller :ProjectController;
}
}
