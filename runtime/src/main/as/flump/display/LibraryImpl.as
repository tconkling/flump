package flump.display {

import flash.utils.Dictionary;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.textures.Texture;

internal class LibraryImpl implements Library {
    public function LibraryImpl (baseTextures :Vector.<Texture>, creators :Dictionary) {
        _baseTextures = baseTextures;
        _creators = creators;
    }

    public function createMovie (symbol :String) :Movie {
        return Movie(createDisplayObject(symbol));
    }

    public function createImage (symbol :String) :Image {
        const disp :DisplayObject = createDisplayObject(symbol);
        if (disp is Movie) throw new Error(symbol + " is not an Image");
        return Image(disp);
    }

    public function getImageTexture (symbol :String) :Texture {
        checkNotDisposed();
        var creator :SymbolCreator = requireSymbolCreator(symbol);
        if (!(creator is ImageCreator)) throw new Error(symbol + " is not an Image");
        return ImageCreator(creator).texture;
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
        return requireSymbolCreator(name).create(this);
    }

    public function dispose () :void {
        checkNotDisposed();
        for each (var tex :Texture in _baseTextures) {
            tex.dispose();
        }
        _baseTextures = null;
        _creators = null;
    }

    protected function requireSymbolCreator (name :String) :SymbolCreator {
        var creator :SymbolCreator = _creators[name];
        if (creator == null) throw new Error("No such id '" + name + "'");
        return creator;
    }

    protected function checkNotDisposed () :void {
        if (_baseTextures == null) {
            throw new Error("This Library has been disposed");
        }
    }

    protected var _creators :Dictionary;
    protected var _baseTextures :Vector.<Texture>;
}
}
