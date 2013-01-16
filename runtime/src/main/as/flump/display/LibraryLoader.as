//
// Flump - Copyright 2013 Flump Authors

package flump.display {

import flash.utils.ByteArray;

import flump.executor.Executor;
import flump.executor.Future;

import starling.core.Starling;

/**
 * Loads zip files created by the flump exporter and parses them into Library instances.
 */
public class LibraryLoader
{
    /**
     * Loads a Library from the zip in the given bytes.
     *
     * @param bytes The bytes containing the zip
     *
     * @param executor The executor on which the loading should run. If not specified, it'll run on
     * a new single-use executor.
     *
     * @param scaleFactor the desired scale factor of the textures to load. If the Library contains
     * textures with multiple scale factors, loader will load the textures with the scale factor
     * closest to this value. If scaleFactor <= 0 (the default), Starling.contentScaleFactor will be
     * used.
     *
     * @return a Future to use to track the success or failure of loading the resources out of the
     * bytes. If the loading succeeds, the Future's onSuccess will fire with an instance of
     * Library. If it fails, the Future's onFail will fire with the Error that caused the
     * loading failure.
     */
    public static function loadBytes (bytes :ByteArray, executor :Executor=null, scaleFactor :Number=-1) :Future {
        return (executor || new Executor(1)).submit(new Loader(bytes, scaleFactor).load);
    }

    /**
     * Loads a Library from the zip at the given url.
     *
     * @param bytes The url where the zip can be found
     *
     * @param executor The executor on which the loading should run. If not specified, it'll run on
     * a new single-use executor.
     *
     * @param scaleFactor the desired scale factor of the textures to load. If the Library contains
     * textures with multiple scale factors, loader will load the textures with the scale factor
     * closest to this value. If scaleFactor <= 0 (the default), Starling.contentScaleFactor will be
     * used.
     *
     * @return a Future to use to track the success or failure of loading the resources from the
     * url. If the loading succeeds, the Future's onSuccess will fire with an instance of
     * Library. If it fails, the Future's onFail will fire with the Error that caused the
     * loading failure.
     */
    public static function loadURL (url :String, executor :Executor=null, scaleFactor :Number=-1) :Future {
        return (executor || new Executor(1)).submit(new Loader(url, scaleFactor).load);
    }

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
    public static const VERSION :String = "2";
}

}

import flash.events.Event;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import deng.fzip.FZip;
import deng.fzip.FZipErrorEvent;
import deng.fzip.FZipEvent;
import deng.fzip.FZipFile;

import flump.display.Library;
import flump.display.LibraryLoader;
import flump.display.Movie;
import flump.executor.Executor;
import flump.executor.Future;
import flump.executor.FutureTask;
import flump.executor.load.ImageLoader;
import flump.executor.load.LoadedImage;
import flump.mold.AtlasMold;
import flump.mold.AtlasTextureMold;
import flump.mold.LibraryMold;
import flump.mold.MovieMold;
import flump.mold.TextureGroupMold;

import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.textures.Texture;

interface SymbolCreator
{
    function create (library :Library) :DisplayObject;
}

class LibraryImpl
    implements Library
{
    public function LibraryImpl (baseTextures :Vector.<Texture>, creators :Dictionary) {
        _baseTextures = baseTextures;
        _creators = creators;
    }

    public function createMovie (symbol :String) :Movie {
        return Movie(createDisplayObject(symbol));
    }

    public function createImage (symbol :String) :Image {
        const disp :DisplayObject = createDisplayObject(symbol);
        if (disp is Movie) throw new Error(symbol + " is a movie, not a texture");
        return Image(disp);
    }

    public function get movieSymbols () :Vector.<String> {
        checkNotDisposed();
        const names :Vector.<String> = new <String>[];
        for (var creatorName :String in _creators) {
            if (_creators[creatorName] is MovieCreator) names.push(creatorName);
        }
        return names;
    }

    public function get imageSymbols () :Vector.<String> {
        checkNotDisposed();
        const names :Vector.<String> = new <String>[];
        for (var creatorName :String in _creators) {
            if (_creators[creatorName] is ImageCreator) names.push(creatorName);
        }
        return names;
    }

    public function createDisplayObject (name :String) :DisplayObject {
        checkNotDisposed();
        var creator :SymbolCreator = _creators[name];
        if (creator == null) throw new Error("No such id '" + name + "'");
        return creator.create(this);
    }

    public function dispose () :void {
        checkNotDisposed();
        for each (var tex :Texture in _baseTextures) {
            tex.dispose();
        }
        _baseTextures = null;
        _creators = null;
    }

    protected function checkNotDisposed () :void {
        if (_baseTextures == null) {
            throw new Error("This Library has been disposed");
        }
    }

    protected var _creators :Dictionary;
    protected var _baseTextures :Vector.<Texture>;
}

class Loader
{
    public function Loader (toLoad :Object, scaleFactor :Number) {
        _scaleFactor = (scaleFactor > 0 ? scaleFactor : Starling.contentScaleFactor);
        _toLoad = toLoad;
    }

    public function load (future :FutureTask) :void {
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
        if (name == LibraryLoader.LIBRARY_LOCATION) {
            const jsonString :String = loaded.content.readUTFBytes(loaded.content.length);
            _lib = LibraryMold.fromJSON(JSON.parse(jsonString));
        } else if (name.indexOf(PNG, name.length - PNG.length) != -1) {
            _pngBytes[name] = loaded.content;
        } else if (name == LibraryLoader.VERSION_LOCATION) {
            const zipVersion :String = loaded.content.readUTFBytes(loaded.content.length)
            if (zipVersion != LibraryLoader.VERSION) {
                throw new Error("Zip is version " + zipVersion + " but the code needs " + LibraryLoader.VERSION);
            }
            _versionChecked = true;
        } else if (name == LibraryLoader.MD5_LOCATION ) { // Nothing to verify
        } else {} // ignore unknown files
    }

    protected function onZipLoadingComplete (..._) :void {
        _zip = null;
        if (_lib == null) throw new Error(LibraryLoader.LIBRARY_LOCATION + " missing from zip");
        if (!_versionChecked) throw new Error(LibraryLoader.VERSION_LOCATION + " missing from zip");
        const loader :ImageLoader = new ImageLoader();
        _pngLoaders.terminated.add(_future.monitoredCallback(onPngLoadingComplete));

        // Determine the scale factor we want to use
        var textureGroup :TextureGroupMold = _lib.bestTextureGroupForScaleFactor(_scaleFactor);
        if (textureGroup != null) {
            for each (var atlas :AtlasMold in textureGroup.atlases) {
                loadAtlas(loader, atlas);
            }
        }
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
            var scale :Number = atlas.scaleFactor;
            const baseTexture :Texture = Texture.fromBitmapData(
                img.bitmapData,
                false,   // generateMipMaps
                false,  // optimizeForRenderToTexture
                scale);

            _baseTextures.push(baseTexture);

            if (!Starling.handleLostContext) {
                img.bitmapData.dispose();
            }

            for each (var atlasTexture :AtlasTextureMold in atlas.textures) {
                var bounds :Rectangle = atlasTexture.bounds;
                var offset :Point = atlasTexture.origin;

                // Starling expects subtexture bounds to be unscaled
                if (scale != 1) {
                    bounds = bounds.clone();
                    bounds.x /= scale;
                    bounds.y /= scale;
                    bounds.width /= scale;
                    bounds.height /= scale;

                    offset = offset.clone();
                    offset.x /= scale;
                    offset.y /= scale;
                }

                _creators[atlasTexture.symbol] = new ImageCreator(
                    Texture.fromTexture(baseTexture, bounds),
                    offset,
                    atlasTexture.symbol);
            }
        });
    }

    protected function onPngLoadingComplete (..._) :void {
        for each (var movie :MovieMold in _lib.movies) {
            movie.fillLabels();
            _creators[movie.id] = new MovieCreator(movie, _lib.frameRate);
        }
        _future.succeed(new LibraryImpl(_baseTextures, _creators));
    }

    protected function onPngLoadingFailed (e :*) :void {
        if (_future.isComplete) return;
        _future.fail(e);
        _pngLoaders.shutdownNow();
    }

    protected var _toLoad :Object;
    protected var _scaleFactor :Number;
    protected var _future :FutureTask;
    protected var _versionChecked :Boolean;

    protected var _zip :FZip = new FZip();
    protected var _lib :LibraryMold;

    protected const _baseTextures :Vector.<Texture> = new <Texture>[];
    protected const _creators :Dictionary = new Dictionary();//<name, ImageCreator/MovieCreator>
    protected const _pngBytes :Dictionary = new Dictionary();//<String name, ByteArray>
    protected const _pngLoaders :Executor = new Executor(1);

    protected static const PNG :String = ".png";
}

class ImageCreator
    implements SymbolCreator
{
    public var texture :Texture;
    public var origin :Point;
    public var symbol :String;

    public function ImageCreator (texture :Texture, origin :Point, symbol :String) {
        this.texture = texture;
        this.origin = origin;
        this.symbol = symbol;
    }

    public function create (library :Library) :DisplayObject {
        const image :Image = new Image(texture);
        image.pivotX = origin.x;
        image.pivotY = origin.y;
        image.name = symbol;
        return image;
    }
}

class MovieCreator
    implements SymbolCreator
{
    public var mold :MovieMold;
    public var frameRate :Number;

    public function MovieCreator (mold :MovieMold, frameRate :Number) {
        this.mold = mold;
        this.frameRate = frameRate;
    }

    public function create (library :Library) :DisplayObject {
        return new Movie(mold, frameRate, library);
    }
}
