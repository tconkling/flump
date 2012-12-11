//
// Flump - Copyright 2012 Three Rings Design

package flump.display {

import starling.animation.Juggler;
import starling.display.DisplayObject;

/**
 * Container for Movie and texture symbols created by the flump exporter.
 */
public interface Library
{
    /** @return the names of all Movie symbols in the Library */
    function get movieSymbols () :Vector.<String>;

    /** @return the names of all iamge symbols in the Library */
    function get imageSymbols () :Vector.<String>;

    /**
     * Creates a movie for the given symbol.
     *
     * @param symbolName the symbol name of the movie to be created
     *
     * @param juggler the Juggler to animate the movie with (or null to use the default juggler)
     *
     * @return a Movie instance for the symbol
     *
     * @throws Error if there is no such symbol in these resources, or if the symbol isn't a Movie.
     */
    function createMovie (symbolName :String, juggler :Juggler = null) :Movie;

    /**
     * Creates an image for the given symbol.
     *
     * @param symbolName the symbol name of the image to be created
     *
     * @return a DisplayObject instance for the symbol
     *
     * @throws Error if there is no such symbol in these resources, or if the symbol isn't a texture.
     */
    function createImage (symbolName :String) :DisplayObject;

    /** Creates an instance of the given Movie or Image symbol */
    function createDisplayObject (symbolName :String, juggler :Juggler = null) :DisplayObject;
}

}
