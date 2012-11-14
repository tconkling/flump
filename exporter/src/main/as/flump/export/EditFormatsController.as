//
// flump-exporter

package flump.export {

import flash.events.MouseEvent;

import mx.collections.ArrayList;
import mx.events.CollectionEvent;

import org.osflash.signals.Signal;

import spark.events.GridSelectionEvent;

public class EditFormatsController
{
    public const formatsChanged :Signal = new Signal();

    public function EditFormatsController (conf :ProjectConf) {
        _win = new EditFormatsWindow();
        _win.open();

        var dataProvider :ArrayList = new ArrayList(conf.exports);
        dataProvider.addEventListener(CollectionEvent.COLLECTION_CHANGE, function (..._) :void {
            formatsChanged.dispatch();
        });

        _win.exports.dataProvider = dataProvider;
        _win.buttonAdd.addEventListener(MouseEvent.CLICK, function (..._) :void {
            var export :ExportConf = new ExportConf();
            export.name = "format" + (conf.exports.length+1);
            if (conf.exports.length > 0) {
                export.format = conf.exports[0].format;
            }
            dataProvider.addItem(export);
        });

        _win.exports.addEventListener(GridSelectionEvent.SELECTION_CHANGE, function (..._) :void {
            _win.buttonRemove.enabled = (_win.exports.selectedItem != null);
        });

        _win.buttonRemove.addEventListener(MouseEvent.CLICK, function (..._) :void {
            for each (var export :ExportConf in _win.exports.selectedItems) {
                dataProvider.removeItem(export);
            }
        });
    }

    public function show () :void {
        _win.orderToFront();
    }

    public function get closed () :Boolean {
        return _win.closed;
    }

    protected var _win :EditFormatsWindow;
}
}