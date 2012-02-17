//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flump.display.DisplayCreator;
import flump.xfl.XflLibrary;
import flump.xfl.XflMovie;
import flump.xfl.XflTexture;

import spark.events.GridSelectionEvent;

import starling.display.DisplayObject;
import starling.display.Sprite;

public class PreviewController
{
    public function PreviewController (lib :XflLibrary, container :Sprite,
            controls :PreviewControlsWindow) {
        _container = container;
        _controls = controls;
        _creator = new DisplayCreator(lib);

        for each (var movie :XflMovie in lib.movies) {
            _controls.movies.dataProvider.addItem({movie: movie.symbol, memory: 0, drawn: 0});
        }
        for each (var tex :XflTexture in lib.textures) {
            _controls.textures.dataProvider.addItem({texture: tex.symbol, memory: 0, drawn: 0});
        }
        _controls.movies.addEventListener(GridSelectionEvent.SELECTION_CHANGE,
            function (..._) :void {
                _controls.textures.selectedIndex = -1;
                displaySymbol(_controls.movies.selectedItem.movie);
            });
        _controls.textures.addEventListener(GridSelectionEvent.SELECTION_CHANGE,
            function (..._) :void {
                _controls.movies.selectedIndex = -1;
                displaySymbol(_controls.textures.selectedItem.texture);
            });

        // Play the first movie
        _controls.movies.selectedIndex = 0;
        // Grumble, wish setting the index above would fire the listener
        displaySymbol(lib.movies[0].symbol);
    }

    protected function displaySymbol (symbol :String) :void {
        while (_container.numChildren > 0) _container.removeChildAt(0);
        const display :DisplayObject = _creator.loadSymbol(symbol);
        // TODO - get the size from the container sprite?
        display.x = 320 - display.width/2;
        display.y = 480 - display.height/2;
        _container.addChild(display);
    }

    protected var _container :Sprite;
    protected var _controls :PreviewControlsWindow;
    protected var _creator :DisplayCreator;
}
}
