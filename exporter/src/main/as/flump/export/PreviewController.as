//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.events.Event;
import flash.geom.Rectangle;

import flump.mold.MovieMold;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

import spark.events.GridSelectionEvent;
import spark.formatters.NumberFormatter;

import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Sprite;

public class PreviewController
{
    public function show (lib :XflLibrary) :void {
        if (_controlsWindow == null || _controlsWindow.closed) {
            _controlsWindow = new PreviewControlsWindow();
            _controlsWindow.open();
        } else {
            _controlsWindow.activate();
        }

        if (_previewWindow == null || _previewWindow.closed) {
            _previewWindow = new PreviewWindow();
            _previewWindow.started = function (container :Sprite) :void {
                _container = container;
                Starling.current.stage.addEventListener(Event.RESIZE, onResize);
                showInternal(lib);
            };
            _previewWindow.open();

        } else {
            _previewWindow.activate();
            showInternal(lib);
        }
    }

    protected function showInternal (lib :XflLibrary) :void {
        _creator = new DisplayCreator(lib);

        const intFormatter :NumberFormatter = new NumberFormatter();
        const formatMemory :Function = function (item :Object, ..._) :String {
            return intFormatter.format(item.memory/1024) + "k";
        };
        intFormatter.fractionalDigits = 0;

        // Use a labelFunction so column sorting works as expected
        _controlsWindow.movieMemory.labelFunction = formatMemory;
        _controlsWindow.textureMemory.labelFunction = formatMemory;

        // All explicitly exported movies
        const previewMovies :Vector.<MovieMold> =
            lib.movies.filter(function (movie :MovieMold, ..._) :Boolean {
                return lib.isExported(movie);
            });

        _controlsWindow.movies.dataProvider.removeAll();
        for each (var movie :MovieMold in previewMovies) {
            _controlsWindow.movies.dataProvider.addItem({
                movie: movie.id,
                memory: _creator.getMemoryUsage(movie.id),
                drawn: _creator.getMaxDrawn(movie.id)
            });
        }

        var totalUsage :int = 0;
        _controlsWindow.textures.dataProvider.removeAll();
        for each (var tex :XflTexture in lib.textures) {
            var itemUsage :int = _creator.getMemoryUsage(tex.symbol);
            totalUsage += itemUsage;
            _controlsWindow.textures.dataProvider.addItem({texture: tex.symbol, memory: itemUsage});
        }
        _controlsWindow.totalValue.text = formatMemory({memory: totalUsage});

        const packer :TexturePacker = new TexturePacker(lib);
        var atlasSize :Number = 0;
        var atlasUsed :Number = 0;
        for each (var atlas :Atlas in packer.atlases) {
            atlasSize += atlas.area;
            atlasUsed += atlas.used;
        }
        const percentFormatter :NumberFormatter = new NumberFormatter();
        percentFormatter.fractionalDigits = 2;
        _controlsWindow.atlasWasteValue.text = percentFormatter.format((1.0 - (atlasUsed/atlasSize)) * 100) + "%";

        _controlsWindow.movies.addEventListener(GridSelectionEvent.SELECTION_CHANGE,
            function (..._) :void {
                _controlsWindow.textures.selectedIndex = -1;
                displayLibraryItem(_controlsWindow.movies.selectedItem.movie);
        });
        _controlsWindow.textures.addEventListener(GridSelectionEvent.SELECTION_CHANGE,
            function (..._) :void {
                _controlsWindow.movies.selectedIndex = -1;
                displayLibraryItem(_controlsWindow.textures.selectedItem.texture);
        });

        if (previewMovies.length > 0) {
            // Play the first movie
            _controlsWindow.movies.selectedIndex = 0;
            // Grumble, wish setting the index above would fire the listener
            displayLibraryItem(previewMovies[0].id);
        }

        Starling.current.stage.color = lib.backgroundColor;
    }

    protected function displayLibraryItem (name :String) :void {
        while (_container.numChildren > 0) _container.removeChildAt(0);
        _previewSprite = _creator.loadId(name);
        _container.addChild(_previewSprite);
        onResize();
    }

    protected function onResize (..._) :void {
        var bounds :Rectangle = _previewSprite.getBounds(_previewSprite);
        _previewSprite.x = ((_previewWindow.width - bounds.width) * 0.5) - bounds.left;
        _previewSprite.y = ((_previewWindow.height - bounds.height) * 0.5) - bounds.top;
    }

    protected var _previewSprite :DisplayObject;
    protected var _container :Sprite;
    protected var _controlsWindow :PreviewControlsWindow;
    protected var _previewWindow :PreviewWindow;
    protected var _creator :DisplayCreator;
}
}
