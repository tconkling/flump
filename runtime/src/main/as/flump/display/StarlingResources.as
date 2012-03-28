//
// Flump - Copyright 2012 Three Rings Design

package flump.display {

import flash.net.URLRequest;
import flash.utils.Dictionary;

import flump.executor.Future;

import starling.display.DisplayObject;

public class StarlingResources
{
    public static const LIBRARY_LOCATION :String = "library.amf";
    public static const MD5_LOCATION :String = "md5";

    public static function loadURL (url :String) :Future {
        const loader :Loader = new Loader();
        loader.zip.load(new URLRequest(url));
        return loader;
    }

    public function StarlingResources (creators :Dictionary) {
        _creators = creators;
    }

    public function loadMovie (name :String) :Movie {
        return Movie(idToDisplayObject(name));
    }

    public function loadTexture (name :String) :DisplayObject {
        return DisplayObject(idToDisplayObject(name));
    }

    public function get movieNames () :Vector.<String> {
        const names :Vector.<String> = new Vector.<String>();
        for (var creatorName :String in _creators) {
            if (_creators[creatorName] is MovieCreator) names.push(creatorName);
        }
        return names;
    }

    public function get textureNames () :Vector.<String> {
        const names :Vector.<String> = new Vector.<String>();
        for (var creatorName :String in _creators) {
            if (_creators[creatorName] is TextureCreator) names.push(creatorName);
        }
        return names;
    }

    protected function idToDisplayObject (name :String) :DisplayObject {
        // TODO - fail on missing item
        return _creators[name].create(idToDisplayObject);
    }

    protected var _creators :Dictionary;
}
}
import flash.events.Event;
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
import flump.mold.Molds;
import flump.mold.MovieMold;

import starling.textures.Texture;

class Loader extends VisibleFuture
{
    public var zip :FZip = new FZip();

    public function Loader() {
        Molds.registerClassAliases();
        // Don't keep the zip in memory after completion
        completed.add(function (..._) :void { zip = null; });

        zip.addEventListener(Event.COMPLETE, onZipLoadingComplete);
        zip.addEventListener(FZipErrorEvent.PARSE_ERROR, fail);
        zip.addEventListener(FZipEvent.FILE_LOADED, onFileLoaded);
    }

    protected function onFileLoaded (e :FZipEvent) :void {
        const loaded :FZipFile = zip.removeFileAt(zip.getFileCount() - 1);
        const name :String = loaded.filename;
        if (name == StarlingResources.LIBRARY_LOCATION) {
            _lib = loaded.content.readObject();
        } else if (name == StarlingResources.MD5_LOCATION ) { // Nothing to verify
        } else if (name.indexOf('.png', name.length - 4) != -1) {
            // TODO - specify density?
            _pngBytes[name.replace("@2x.png", ".png")] = loaded.content;
        } else { trace("Unknown file in zip '" + name + "'. Ignoring."); }
    }

    protected function onZipLoadingComplete (..._) :void {
        const loader :ImageLoader = new ImageLoader();
        _pngLoaders.terminated.add(onPngLoadingComplete);
        for each (var atlas :AtlasMold in _lib.atlases) loadAtlas(loader, atlas);
        _pngLoaders.shutdown();
    }

    public function loadAtlas (loader :ImageLoader, atlas :AtlasMold) :void {
        // TODO check for missing _pngBytes
        var atlasFuture :Future = loader.loadFromBytes(_pngBytes[atlas.file], _pngLoaders);
        atlasFuture.failed.add(onPngLoadingFailed);
        atlasFuture.succeeded.add(function (img :LoadedImage) :void {
            const baseTexture :Texture = Texture.fromBitmapData(img.bitmapData);
            for each (var atlasTexture :AtlasTextureMold in atlas.textures) {
                const creator :TextureCreator = new TextureCreator();
                creator.offset = atlasTexture.offset;
                creator.texture = Texture.fromTexture(baseTexture, atlasTexture.bounds);
                _creators[atlasTexture.name] = creator;
            }
        });
    }

    public function onPngLoadingComplete (..._) :void {
        for each (var movie :MovieMold in _lib.movies) {
            var creator :MovieCreator = new MovieCreator();
            creator.frameRate = _lib.frameRate;
            creator.mold = movie;
            _creators[movie.libraryItem] = creator;
        }
        succeed(new StarlingResources(_creators));
    }

    public function onPngLoadingFailed (e :*) :void {
        // TODO - stop loading, fail everything
        trace("Png loading failed!" + e)
    }

    protected var _creators :Dictionary = new Dictionary();//<name, TextureCreator/MovieCreator>
    protected var _lib :LibraryMold;
    protected var _pngBytes :Dictionary = new Dictionary();//<String name, ByteArray>
    protected var _pngLoaders :Executor = new Executor();
}
import flash.geom.Point;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

class TextureCreator {
    public var texture :Texture;
    public var offset :Point;

    public function create (..._) :DisplayObject {
        const image :Image = new Image(texture);
        image.x = offset.x;
        image.y = offset.y;
        const holder :Sprite = new Sprite();
        holder.addChild(image);
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
