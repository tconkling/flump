//
// Flump - Copyright 2013 Flump Authors

package flump.display {

import deng.fzip.FZip;
import deng.fzip.FZipErrorEvent;
import deng.fzip.FZipEvent;
import deng.fzip.FZipFile;

import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

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
import starling.textures.Texture;

internal class Loader {
    public function Loader (toLoad :Object, libLoader :LibraryLoader) {
        _scaleFactor = (libLoader.scaleFactor > 0 ? libLoader.scaleFactor :
            Starling.contentScaleFactor);
        _libLoader = libLoader;
        _toLoad = toLoad;
    }

    public function load (future :FutureTask) :void {
        _future = future;

        _zip.addEventListener(Event.COMPLETE, _future.monitoredCallback(onZipLoadingComplete));
        _zip.addEventListener(IOErrorEvent.IO_ERROR, _future.fail);
        _zip.addEventListener(FZipErrorEvent.PARSE_ERROR, _future.fail);
        _zip.addEventListener(FZipEvent.FILE_LOADED, _future.monitoredCallback(onFileLoaded));
        _zip.addEventListener(ProgressEvent.PROGRESS, _future.monitoredCallback(onProgress));

        if (_toLoad is String) _zip.load(new URLRequest(String(_toLoad)));
        else _zip.loadBytes(ByteArray(_toLoad));
    }

    protected function onProgress (e :ProgressEvent) :void {
        _libLoader.urlLoadProgressed.emit(e);
    }

    protected function onFileLoaded (e :FZipEvent) :void {
        const loaded :FZipFile = _zip.removeFileAt(_zip.getFileCount() - 1);
        const name :String = loaded.filename;
        if (name == LibraryLoader.LIBRARY_LOCATION) {
            const jsonString :String = loaded.content.readUTFBytes(loaded.content.length);
            _lib = LibraryMold.fromJSON(JSON.parse(jsonString));
            _libLoader.libraryMoldLoaded.emit(_lib);
        } else if (name.indexOf(PNG, name.length - PNG.length) != -1) {
            _atlasBytes[name] = loaded.content;
        } else if (name.indexOf(ATF, name.length - ATF.length) != -1) {
            _atlasBytes[name] = loaded.content;
            _libLoader.atfAtlasLoaded.emit({name: name, bytes: loaded.content});
        } else if (name == LibraryLoader.VERSION_LOCATION) {
            const zipVersion :String = loaded.content.readUTFBytes(loaded.content.length);
            if (zipVersion != LibraryLoader.VERSION) {
                throw new Error("Zip is version " + zipVersion + " but the code needs " +
                    LibraryLoader.VERSION);
            }
            _versionChecked = true;
        } else if (name == LibraryLoader.MD5_LOCATION ) { // Nothing to verify
        } else {
            _libLoader.fileLoaded.emit({name: name, bytes: loaded.content});
        }
    }

    protected function onZipLoadingComplete (..._) :void {
        _zip = null;
        if (_lib == null) throw new Error(LibraryLoader.LIBRARY_LOCATION + " missing from zip");
        if (!_versionChecked) throw new Error(LibraryLoader.VERSION_LOCATION + " missing from zip");
        const loader :ImageLoader = _lib.textureFormat == "atf" ? null : new ImageLoader();
        _pngLoaders.terminated.connect(_future.monitoredCallback(onPngLoadingComplete));

        // Determine the scale factor we want to use
        var textureGroup :TextureGroupMold = _lib.bestTextureGroupForScaleFactor(_scaleFactor);
        if (textureGroup != null) {
            for each (var atlas :AtlasMold in textureGroup.atlases) {
                loadAtlas(loader, atlas);
            }
        }
        // free up extra atlas bytes immediately
        for (var leftover :String in _atlasBytes) {
            if (_atlasBytes.hasOwnProperty(leftover)) {
                ByteArray(_atlasBytes[leftover]).clear();
                delete (_atlasBytes[leftover]);
            }
        }
        _pngLoaders.shutdown();
    }

    protected function loadAtlas (loader :ImageLoader, atlas :AtlasMold) :void {
        const bytes :* = _atlasBytes[atlas.file];
        delete _atlasBytes[atlas.file];
        if (bytes === undefined) {
            throw new Error("Expected an atlas '" + atlas.file + "', but it wasn't in the zip");
        }

        ByteArray(bytes).position = 0; // reset the read head
        var scale :Number = atlas.scaleFactor;
        if (_lib.textureFormat == "atf") {
            baseTextureLoaded(Texture.fromAtfData(bytes, scale, _libLoader.generateMipMaps), atlas);
            if (!Starling.handleLostContext) {
                ByteArray(bytes).clear();
            }
        } else {
            const atlasFuture :Future = loader.loadFromBytes(bytes, _pngLoaders);
            atlasFuture.failed.connect(onPngLoadingFailed);
            atlasFuture.succeeded.connect(function (img :LoadedImage) :void {
                _libLoader.pngAtlasLoaded.emit({atlas: atlas, image: img});
                baseTextureLoaded(Texture.fromBitmapData(
                    img.bitmapData,
                    _libLoader.generateMipMaps,
                    false,  // optimizeForRenderToTexture
                    scale), atlas);
                if (!Starling.handleLostContext) {
                    img.bitmapData.dispose();
                }
                ByteArray(bytes).clear();
            });

        }
    }

    protected function baseTextureLoaded (baseTexture :Texture, atlas :AtlasMold) :void {
        _baseTextures.push(baseTexture);

        _libLoader.creatorFactory.consumingAtlasMold(atlas);
        var scale :Number = atlas.scaleFactor;
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

            _creators[atlasTexture.symbol] = _libLoader.creatorFactory.createImageCreator(
                atlasTexture,
                Texture.fromTexture(baseTexture, bounds),
                offset,
                atlasTexture.symbol);
        }
    }

    protected function onPngLoadingComplete (..._) :void {
        for each (var movie :MovieMold in _lib.movies) {
            movie.fillLabels();
            _creators[movie.id] = _libLoader.creatorFactory.createMovieCreator(
                movie, _lib.frameRate);
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
    protected var _libLoader :LibraryLoader;
    protected var _future :FutureTask;
    protected var _versionChecked :Boolean;

    protected var _zip :FZip = new FZip();
    protected var _lib :LibraryMold;

    protected const _baseTextures :Vector.<Texture> = new <Texture>[];
    protected const _creators :Dictionary = new Dictionary();//<name, ImageCreator/MovieCreator>
    protected const _atlasBytes :Dictionary = new Dictionary();//<String name, ByteArray>
    protected const _pngLoaders :Executor = new Executor(1);

    protected static const PNG :String = ".png";
    protected static const ATF :String = ".atf";
}
}
