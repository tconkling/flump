//
// aciv

package flump.display {

import flash.events.Event;
import flash.events.FileListEvent;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.filesystem.File;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import flump.FlumpCodes;

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

internal class FlumpDirectoryLoader {
    public function FlumpDirectoryLoader (dir :File, libLoader :LibraryLoader) {
        _dir = dir;
        _scaleFactor = (libLoader.scaleFactor > 0 ? libLoader.scaleFactor :
            Starling.contentScaleFactor);
        _libLoader = libLoader;
    }

    public function load (future :FutureTask) :void {
        _future = future;

        if (!_dir.exists) {
            _future.fail("Directory doesn't exist [path=" + _dir.nativePath + "]");
        } else if (!_dir.isDirectory) {
            _future.fail("Not a directory [path=" + _dir.nativePath + "]");
        } else {
            _dir.addEventListener(IOErrorEvent.IO_ERROR, _future.fail);
            _dir.addEventListener(FileListEvent.DIRECTORY_LISTING, onDirectoryListing);
            _future.monitor(_dir.getDirectoryListingAsync);
        }
    }

    protected function onDirectoryListing (event :FileListEvent) :void {
        for each (var file :File in event.files) {
            if (getFileType(file.name) != null) {
                _totalBytes += file.size;
                _remainingFiles++;
                file.addEventListener(ProgressEvent.PROGRESS, _future.monitoredCallback(onFileProgress));
                var fileFuture :Future = loadFile(file, _fileLoaders);
                fileFuture.failed.connect(onFileLoadingFailed);
                fileFuture.succeeded.connect(onFileLoaded);

            } else {
                _libLoader.unrecognizedFileFound.emit(file);
            }
        }

        if (_remainingFiles == 0) {
            onAllFilesLoaded();
        }
    }

    protected function onFileProgress (event :ProgressEvent) :void {
        if (_future.isComplete) {
            return;
        }

        _fileProgress[event.target] = event.bytesLoaded;
        var totalBytesLoaded :Number = 0;
        for (var file :File in _fileProgress) {
            var fileBytesLoaded :Number = _fileProgress[file];
            totalBytesLoaded += fileBytesLoaded;
        }

        _libLoader.urlLoadProgressed.emit(
            new ProgressEvent(ProgressEvent.PROGRESS, false, false, totalBytesLoaded, _totalBytes));
    }

    protected function onFileLoaded (file :File) :void {
        switch (getFileType(file.name)) {
        case FILE_TYPE_LIBRARY:
            var jsonString :String = file.data.readUTFBytes(file.data.length);
            _lib = LibraryMold.fromJSON(JSON.parse(jsonString));
            _libLoader.libraryMoldLoaded.emit(_lib);
            break;

        case FILE_TYPE_PNG:
            _atlasBytes[file.name] = file.data;
            break;

        case FILE_TYPE_ATF:
            _atlasBytes[file.name] = file.data;
            _libLoader.atfAtlasLoaded.emit({name: file.name, bytes: file.data});
            break;
        }

        if (--_remainingFiles == 0) {
            _future.monitor(onAllFilesLoaded);
        }
    }

    protected function onFileLoadingFailed (e :*) :void {
        if (_future.isComplete) {
            return;
        }
        _future.fail(e);
        _fileLoaders.shutdownNow();
    }

    protected function onAllFilesLoaded () :void {
        if (_lib == null) {
            throw new Error(FlumpCodes.LIBRARY_FILENAME + " missing from directory");
        }

        var imageLoader :ImageLoader;
        if (_lib.textureFormat != "atf") {
            imageLoader = new ImageLoader();
        }

        _fileLoaders.terminated.connect(_future.monitoredCallback(onPngLoadingComplete));

        // Determine the scale factor we want to use
        var textureGroup :TextureGroupMold = _lib.bestTextureGroupForScaleFactor(_scaleFactor);
        if (textureGroup != null) {
            for each (var atlas :AtlasMold in textureGroup.atlases) {
                loadAtlas(imageLoader, atlas);
            }
        }

        // free up extra atlas bytes immediately
        for (var leftover :String in _atlasBytes) {
            if (_atlasBytes.hasOwnProperty(leftover)) {
                ByteArray(_atlasBytes[leftover]).clear();
                delete (_atlasBytes[leftover]);
            }
        }
        _fileLoaders.shutdown();
    }

    protected function loadAtlas (loader :ImageLoader, atlas :AtlasMold) :void {
        const bytes :* = _atlasBytes[atlas.file];
        delete _atlasBytes[atlas.file];

        ByteArray(bytes).position = 0; // reset the read head
        var scale :Number = atlas.scaleFactor;
        if (_lib.textureFormat == "atf") {
            // we do not dipose of the ByteArray so that Starling will handle a context loss.
            addBaseTexture(Texture.fromAtfData(bytes, scale, _libLoader.generateMipMaps), atlas);
        } else {
            const atlasFuture :Future = loader.loadFromBytes(bytes, _fileLoaders);
            atlasFuture.failed.connect(onFileLoadingFailed);
            atlasFuture.succeeded.connect(function (img :LoadedImage) :void {
                _libLoader.pngAtlasLoaded.emit({atlas: atlas, image: img});
                addBaseTexture(Texture.fromBitmapData(
                    img.bitmapData,
                    _libLoader.generateMipMaps,
                    false,  // optimizeForRenderToTexture
                    scale), atlas);
                // We dispose of the ByteArray, but not the BitmapData,
                // so that Starling will handle a context loss.
                ByteArray(bytes).clear();
            });
        }
    }

    protected function addBaseTexture (baseTexture :Texture, atlas :AtlasMold) :void {
        _baseTextures[_baseTextures.length] = baseTexture;

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

            _symbolCreators[atlasTexture.symbol] = _libLoader.creatorFactory.createImageCreator(
                atlasTexture,
                Texture.fromTexture(baseTexture, bounds),
                offset,
                atlasTexture.symbol);
        }
    }

    protected function onPngLoadingComplete (..._) :void {
        for each (var movie :MovieMold in _lib.movies) {
            movie.fillLabels();
            _symbolCreators[movie.id] = _libLoader.creatorFactory.createMovieCreator(
                movie, _lib.frameRate);
        }
        _future.succeed(new LibraryImpl(_baseTextures, _symbolCreators, _lib.isNamespaced));
    }

    /**
     * Loads a file asynchronously.
     * Returns a Future that will succeed with the passed-in File when loading is complete.
     */
    protected static function loadFile (file :File, exec :Executor = null) :Future {
        if (exec == null) {
            exec = new Executor();
        }

        return exec.submit(function (onSuccess :Function, onFail :Function) :void {
            file.addEventListener(IOErrorEvent.IO_ERROR, onFail);
            file.addEventListener(Event.COMPLETE, function (event :Event) :void {
                onSuccess(file);
            });

            try {
                file.load();
            } catch (error :Error) {
                onFail(error);
            }
        });
    }

    protected static function getFileType (name :String) :String {
        if (name == FlumpCodes.LIBRARY_FILENAME) {
            return FILE_TYPE_LIBRARY;
        } else if (name.indexOf(FlumpCodes.PNG_EXT, name.length - FlumpCodes.PNG_EXT.length) != -1) {
            return FILE_TYPE_PNG;
        } else if (name.indexOf(FlumpCodes.ATF_EXT, name.length - FlumpCodes.ATF_EXT.length) != -1) {
            return FILE_TYPE_ATF;
        } else {
            return null;
        }
    }

    protected var _dir :File;
    protected var _scaleFactor :Number;
    protected var _libLoader :LibraryLoader;
    protected var _future :FutureTask;

    protected var _remainingFiles :int;
    protected var _totalBytes :Number = 0;
    protected var _fileProgress :Dictionary = new Dictionary(); // <File, bytesLoaded>
    protected var _atlasBytes :Dictionary = new Dictionary(); //<String name, ByteArray>
    protected var _fileLoaders :Executor = new Executor(1);

    protected var _baseTextures :Vector.<Texture> = new <Texture>[];
    protected var _symbolCreators :Dictionary = new Dictionary();//<name, ImageCreator/MovieCreator>
    protected var _lib :LibraryMold;

    protected static const FILE_TYPE_LIBRARY :String = "library";
    protected static const FILE_TYPE_PNG :String = "png";
    protected static const FILE_TYPE_ATF :String = "atf";
}
}
