//
// flump-exporter

package flump.export {

import flash.filesystem.File;

public class FlumpApp
{
    public function run () :void {
        _controller = new ProjectController(FlumpSettings.hasConfigFilePath ?
            new File(FlumpSettings.configFilePath) : null);
    }

    protected var _controller :ProjectController;
}
}
