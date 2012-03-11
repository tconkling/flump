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
        this.lib = lib;
    }

    public function set lib (lib :XflLibrary) :void {
        _creator = new DisplayCreator(lib);

        _controls.movies.dataProvider.removeAll();
        for each (var movie :XflMovie in lib.movies) {
            _controls.movies.dataProvider.addItem({movie: movie.libraryItem,
                memory: _creator.getMemoryUsage(movie.libraryItem), drawn: 0});
        }
        _controls.textures.dataProvider.removeAll();
        for each (var tex :XflTexture in lib.textures) {
            _controls.textures.dataProvider.addItem({texture: tex.libraryItem,
              memory:_creator.getMemoryUsage(tex.libraryItem)});
        }
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

        // Play the first movie
        _controls.movies.selectedIndex = 0;
        // Grumble, wish setting the index above would fire the listener
        displayLibraryItem(lib.movies[0].libraryItem);
    }

    protected function displayLibraryItem (name :String) :void {
        while (_container.numChildren > 0) _container.removeChildAt(0);
        const display :DisplayObject = _creator.loadId(name);
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
