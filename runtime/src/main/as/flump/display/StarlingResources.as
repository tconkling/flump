//
// Flump - Copyright 2012 Three Rings Design

package flump.display {

import flash.utils.ByteArray;
import flash.utils.Dictionary;

import flump.executor.Executor;
import flump.executor.Future;

import starling.display.DisplayObject;

/**
 * Parses movies and textures out of zip files created by the flump exporter and creates instances
 * of Movie for them.
 */
public class StarlingResources
{
    /** @private */
    public static const LIBRARY_LOCATION :String = "library.json";
    /** @private */
    public static const MD5_LOCATION :String = "md5";
    /** @private */
    public static const VERSION_LOCATION :String = "version";

    /**
     * @private
     * The version produced and parsable by this version of the code. The version in a resources
     * zip must equal the version compiled into the parsing code for parsing to succeed.
     */
    public static const VERSION :String = "0";

    /**
     * Loads a StarlingResources from the zip in the given bytes.
     *
     * @param bytes The bytes containing the zip
     * @param executor The executor on which the loading should run. If not specified, it'll run on
     * a new single-use executor.
     *
     * @return a Future to use to track the success or failure of loading the resources out of the
     * bytes. If the loading succeeds, the Future's onSuccess will fire with an instance of
     * StarlingResources. If it fails, the Future's onFail will fire with the Error that caused the
     * loading failure.
     */
    public static function loadBytes (bytes :ByteArray, executor :Executor=null) :Future {
        return (executor || new Executor()).submit(new Loader(bytes).load);
    }

    /**
     * Loads a StarlingResources from the zip at the given url.
     *
     * @param bytes The url where the zip can be found
     * @param executor The executor on which the loading should run. If not specified, it'll run on
     * a new single-use executor.
     *
     * @return a Future to use to track the success or failure of loading the resources from the
     * url. If the loading succeeds, the Future's onSuccess will fire with an instance of
     * StarlingResources. If it fails, the Future's onFail will fire with the Error that caused the
     * loading failure.
     */
    public static function loadURL (url :String, executor :Executor=null) :Future {
        return (executor || new Executor()).submit(new Loader(url).load);
    }

    /** @private */
    public function StarlingResources (creators :Dictionary) {
        _creators = creators;
    }

    /**
     * Creates a movie for the given symbol.
     *
     * @param symbol the symbol name of the movie to be created
     *
     * @return a Movie instance for the symbol
     *
     * @throws Error if there is no such symbol in these resources, or if the symbol isn't a Movie.
     */
    public function createMovie (symbol :String) :Movie { return Movie(idToDisplayObject(symbol)); }

   /**
    * Creates a texture for the given symbol.
    *
    * @param symbol the symbol name of the texture to be created
    *
    * @return a DisplayObject instance for the symbol
    *
    * @throws Error if there is no such symbol in these resources, or if the symbol isn't a texture.
    */
    public function createTexture (symbol :String) :DisplayObject {
        const disp :DisplayObject = DisplayObject(idToDisplayObject(symbol));
        // TODO - add loadDisplayObject to load either if the user doesn't care?
        if (disp is Movie) throw new Error(symbol + " is a movie, not a texture");
        return disp;
    }

    /** The symbols of all movies in the resources.  */
    public function get movieSymbols () :Vector.<String> {
        const names :Vector.<String> = new Vector.<String>();
        for (var creatorName :String in _creators) {
            if (_creators[creatorName] is MovieCreator) names.push(creatorName);
        }
        return names;
    }

    /** The symbols of all textures in the resources.  */
    public function get textureSymbols () :Vector.<String> {
        const names :Vector.<String> = new Vector.<String>();
        for (var creatorName :String in _creators) {
            if (_creators[creatorName] is TextureCreator) names.push(creatorName);
        }
        return names;
    }

    /** @private */
    protected function idToDisplayObject (name :String) :DisplayObject {
        var creator :* = _creators[name];
        if (creator === undefined) throw new Error("No such id '" + name + "'");
        return creator.create(idToDisplayObject);
    }

    /** @private */
    protected var _creators :Dictionary;
}
}
import flash.events.Event;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import deng.fzip.FZip;
import deng.fzip.FZipErrorEvent;
import deng.fzip.FZipEvent;
import deng.fzip.FZipFile;

import flump.display.StarlingResources;
import flump.executor.Executor;
import flump.executor.Future;
import flump.executor.VisibleFuture;
import flump.executor.load.ImageLoader;
import flump.executor.load.LoadedImage;
import flump.mold.AtlasMold;
import flump.mold.AtlasTextureMold;
import flump.mold.LibraryMold;
import flump.mold.MovieMold;

import starling.textures.Texture;

class Loader
{
    public function Loader(toLoad :Object) {
        _toLoad = toLoad;
    }

    public function load(future :VisibleFuture) :void {
        _future = future;

        _zip.addEventListener(Event.COMPLETE, _future.monitoredCallback(onZipLoadingComplete));
        _zip.addEventListener(FZipErrorEvent.PARSE_ERROR, _future.fail);
        _zip.addEventListener(FZipEvent.FILE_LOADED, _future.monitoredCallback(onFileLoaded));

        if (_toLoad is String) _zip.load(new URLRequest(String(_toLoad)));
        else _zip.loadBytes(ByteArray(_toLoad));
    }

    protected function onFileLoaded (e :FZipEvent) :void {
        const loaded :FZipFile = _zip.removeFileAt(_zip.getFileCount() - 1);
        const name :String = loaded.filename;
        if (name == StarlingResources.LIBRARY_LOCATION) {
            const jsonString :String = loaded.content.readUTFBytes(loaded.content.length);
            _lib = LibraryMold.fromJSON(JSON.parse(jsonString));
        } else if (name.indexOf('.png', name.length - 4) != -1) {
            // TODO - specify density?
            _pngBytes[name.replace("@2x.png", ".png")] = loaded.content;
        } else if (name == StarlingResources.VERSION_LOCATION) {
            const zipVersion :String = loaded.content.readUTFBytes(loaded.content.length)
            if (zipVersion != StarlingResources.VERSION) {
                throw new Error("Zip is version " + zipVersion + " but the code needs " + StarlingResources.VERSION);
            }
            _versionChecked = true;
        } else if (name == StarlingResources.MD5_LOCATION ) { // Nothing to verify
        } else {} // ignore unknown files
    }

    protected function onZipLoadingComplete (..._) :void {
        _zip = null;
        if (_lib == null) throw new Error(StarlingResources.LIBRARY_LOCATION + " missing from zip");
        if (!_versionChecked) throw new Error(StarlingResources.VERSION_LOCATION + " missing from zip");
        const loader :ImageLoader = new ImageLoader();
        _pngLoaders.terminated.add(_future.monitoredCallback(onPngLoadingComplete));
        for each (var atlas :AtlasMold in _lib.atlases) loadAtlas(loader, atlas);
        _pngLoaders.shutdown();
    }

    protected function loadAtlas (loader :ImageLoader, atlas :AtlasMold) :void {
        const pngBytes :* = _pngBytes[atlas.file];
        if (pngBytes === undefined) {
            throw new Error("Expected an atlas '" + atlas.file + "', but it wasn't in the zip");
        }
        const atlasFuture :Future = loader.loadFromBytes(pngBytes, _pngLoaders);
        atlasFuture.failed.add(onPngLoadingFailed);
        atlasFuture.succeeded.add(function (img :LoadedImage) :void {
            const baseTexture :Texture = Texture.fromBitmapData(img.bitmapData);
            for each (var atlasTexture :AtlasTextureMold in atlas.textures) {
                const creator :TextureCreator = new TextureCreator();
                creator.offset = atlasTexture.offset;
                creator.texture = Texture.fromTexture(baseTexture, atlasTexture.bounds);
                creator.symbol = atlasTexture.symbol;
                _creators[atlasTexture.symbol] = creator;
            }
        });
    }

    protected function onPngLoadingComplete (..._) :void {
        for each (var movie :MovieMold in _lib.movies) {
            movie.fillLabels();
            var creator :MovieCreator = new MovieCreator();
            creator.frameRate = _lib.frameRate;
            creator.mold = movie;
            _creators[movie.id] = creator;
        }
        _future.succeed(new StarlingResources(_creators));
    }

    protected function onPngLoadingFailed (e :*) :void {
        if (_future.isComplete) return;
        _future.fail(e);
        _pngLoaders.shutdownNow();
    }

    protected var _toLoad :Object;
    protected var _future :VisibleFuture;
    protected var _versionChecked :Boolean;

    protected var _zip :FZip = new FZip();
    protected var _lib :LibraryMold;

    protected const _creators :Dictionary = new Dictionary();//<name, TextureCreator/MovieCreator>
    protected const _pngBytes :Dictionary = new Dictionary();//<String name, ByteArray>
    protected const _pngLoaders :Executor = new Executor();
}
import flash.geom.Point;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

class TextureCreator {
    public var texture :Texture;
    public var offset :Point;
    public var symbol :String;

    public function create (..._) :DisplayObject {
        const image :Image = new Image(texture);
        image.x = offset.x;
        image.y = offset.y;
        const holder :Sprite = new Sprite();
        holder.addChild(image);
        holder.name = symbol;
        return holder;
    }
}
import flump.display.Movie;
import flump.mold.MovieMold;

import starling.display.DisplayObject;

class MovieCreator {
    public var frameRate :Number;
    public var mold :MovieMold;

    public function create (idToDisplayObject :Function) :DisplayObject {
        return new Movie(mold, frameRate, idToDisplayObject);
    }
}
