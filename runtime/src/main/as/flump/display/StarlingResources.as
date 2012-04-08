//
// Flump - Copyright 2012 Three Rings Design

package flump.display {

import flash.utils.ByteArray;
import flash.utils.Dictionary;

import flump.executor.Executor;
import flump.executor.Future;

import starling.display.DisplayObject;

public class StarlingResources
{
    public static const LIBRARY_LOCATION :String = "library.json";
    public static const MD5_LOCATION :String = "md5";

    public static function loadBytes (bytes :ByteArray, executor :Executor=null) :Future {
        return (executor || new Executor()).submit(new Loader(bytes).load);
    }

    public static function loadURL (url :String, executor :Executor=null) :Future {
        return (executor || new Executor()).submit(new Loader(url).load);
    }

    public function StarlingResources (creators :Dictionary) {
        _creators = creators;
    }

    public function loadMovie (name :String) :Movie { return Movie(idToDisplayObject(name)); }

    public function loadTexture (name :String) :DisplayObject {
        const disp :DisplayObject = DisplayObject(idToDisplayObject(name));
        // TODO - add loadDisplayObject to load either if the user doesn't care?
        if (disp is Movie) {
            throw new Error(name + " is a movie, not a texture");
        }
        return disp;
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
        var creator :* = _creators[name];
        if (creator === undefined) throw new Error("No such id '" + name + "'");
        return creator.create(idToDisplayObject);
    }

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

    public function load(onSuccess :Function, onFailure :Function) :void {
        _onFailure = onFailure;
        _onSuccess = onSuccess;

        _zip.addEventListener(Event.COMPLETE, onZipLoadingComplete);
        _zip.addEventListener(FZipErrorEvent.PARSE_ERROR, fail);
        _zip.addEventListener(FZipEvent.FILE_LOADED, onFileLoaded);

        if (_toLoad is String) _zip.load(new URLRequest(String(_toLoad)));
        else _zip.loadBytes(ByteArray(_toLoad));
    }

    protected function fail(e :Error) :void {
        _failed = true;
        _onFailure(e);
    }

    protected function onFileLoaded (e :FZipEvent) :void {
        if (_failed) return;
        const loaded :FZipFile = _zip.removeFileAt(_zip.getFileCount() - 1);
        const name :String = loaded.filename;
        if (name == StarlingResources.LIBRARY_LOCATION) {
            const jsonString :String = loaded.content.readUTFBytes(loaded.content.length);
            _lib = LibraryMold.fromJSON(JSON.parse(jsonString));
        } else if (name == StarlingResources.MD5_LOCATION ) { // Nothing to verify
        } else if (name.indexOf('.png', name.length - 4) != -1) {
            // TODO - specify density?
            _pngBytes[name.replace("@2x.png", ".png")] = loaded.content;
        } else { trace("Unknown file in zip '" + name + "'. Ignoring."); }
    }

    protected function onZipLoadingComplete (..._) :void {
        _zip = null;
        if (_failed) return;
        const loader :ImageLoader = new ImageLoader();
        _pngLoaders.terminated.add(onPngLoadingComplete);
        for each (var atlas :AtlasMold in _lib.atlases) loadAtlas(loader, atlas);
        _pngLoaders.shutdown();
    }

    protected function loadAtlas (loader :ImageLoader, atlas :AtlasMold) :void {
        if (_failed) return;
        const pngBytes :* = _pngBytes[atlas.file];
        if (pngBytes === undefined) {
            onPngLoadingFailed(new Error("Expected an atlas '" + atlas.file + "', but it wasn't in the zip"));
            return;
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
        if (_failed) return;
        for each (var movie :MovieMold in _lib.movies) {
            movie.fillLabels();
            var creator :MovieCreator = new MovieCreator();
            creator.frameRate = _lib.frameRate;
            creator.mold = movie;
            _creators[movie.id] = creator;
        }
        _onSuccess(new StarlingResources(_creators));
    }

    protected function onPngLoadingFailed (e :*) :void {
        fail(e);
        _pngLoaders.shutdownNow();
    }

    protected var _toLoad :Object;
    protected var _onFailure :Function;
    protected var _onSuccess :Function;
    protected var _failed :Boolean;

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
