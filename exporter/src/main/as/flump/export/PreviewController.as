//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.geom.Rectangle;

import flump.mold.MovieMold;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

import spark.events.GridSelectionEvent;
import spark.formatters.NumberFormatter;

import starling.display.DisplayObject;
import starling.display.Sprite;

public class PreviewController
{
    public function PreviewController (lib :XflLibrary, container :Sprite,
            preview :PreviewWindow, controls :PreviewControlsWindow) {
        _container = container;
        _preview = preview;
        _controls = controls;
        this.lib = lib;
    }

    public function set lib (lib :XflLibrary) :void {
        _creator = new DisplayCreator(lib);

        const intFormatter :NumberFormatter = new NumberFormatter();
        const formatMemory :Function = function (item :Object, ..._) :String {
            return intFormatter.format(item.memory/1024) + "k";
        };
        intFormatter.fractionalDigits = 0;

        // Use a labelFunction so column sorting works as expected
        _controls.movieMemory.labelFunction = formatMemory;
        _controls.textureMemory.labelFunction = formatMemory;

        // All explicitly exported movies
        const previewMovies :Vector.<MovieMold> =
            lib.movies.filter(function (movie :MovieMold, ..._) :Boolean {
                return lib.isExported(movie);
            });

        _controls.movies.dataProvider.removeAll();
        for each (var movie :MovieMold in previewMovies) {
            _controls.movies.dataProvider.addItem({
                movie: movie.id,
                memory: _creator.getMemoryUsage(movie.id),
                drawn: _creator.getMaxDrawn(movie.id)
            });
        }

        var totalUsage :int = 0;
        _controls.textures.dataProvider.removeAll();
        for each (var tex :XflTexture in lib.textures) {
            var itemUsage :int = _creator.getMemoryUsage(tex.symbol);
            totalUsage += itemUsage;
            _controls.textures.dataProvider.addItem({texture: tex.symbol, memory: itemUsage});
        }
        _controls.totalValue.text = formatMemory({memory: totalUsage});

        const packer :Packer = new Packer(DeviceType.IPHONE, DeviceType.IPHONE, lib)
        var atlasSize :Number = 0;
        var atlasUsed :Number = 0;
        for each (var atlas :Atlas in packer.atlases) {
            atlasSize += atlas.area;
            atlasUsed += atlas.used;
        }
        const percentFormatter :NumberFormatter = new NumberFormatter();
        percentFormatter.fractionalDigits = 2;
        _controls.atlasWasteValue.text = percentFormatter.format((1.0 - (atlasUsed/atlasSize)) * 100) + "%";

        _controls.movies.addEventListener(GridSelectionEvent.SELECTION_CHANGE,
            function (..._) :void {
                _controls.textures.selectedIndex = -1;
                displayLibraryItem(_controls.movies.selectedItem.movie);
        });
        _controls.textures.addEventListener(GridSelectionEvent.SELECTION_CHANGE,
            function (..._) :void {
                _controls.movies.selectedIndex = -1;
                displayLibraryItem(_controls.textures.selectedItem.texture);
        });

        if (previewMovies.length > 0) {
            // Play the first movie
            _controls.movies.selectedIndex = 0;
            // Grumble, wish setting the index above would fire the listener
            displayLibraryItem(previewMovies[0].id);
        }
    }

    protected function displayLibraryItem (name :String) :void {
        while (_container.numChildren > 0) _container.removeChildAt(0);
        var display :DisplayObject = _creator.loadId(name);
        var bounds :Rectangle = display.getBounds(display);
        display.x = ((_preview.width - bounds.width) * 0.5) - bounds.left;
        display.y = ((_preview.height - bounds.height) * 0.5) - bounds.top;
        _container.addChild(display);
    }

    protected var _container :Sprite;
    protected var _controls :PreviewControlsWindow;
    protected var _preview :PreviewWindow;
    protected var _creator :DisplayCreator;
}
}
