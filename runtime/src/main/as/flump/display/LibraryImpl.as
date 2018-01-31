package flump.display {

import flash.utils.Dictionary;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.textures.Texture;

internal class LibraryImpl implements Library {
    public function LibraryImpl (baseTextures :Vector.<Texture>, creators :Dictionary,
            isNamespaced :Boolean, baseScale:Number = 1) {
        _baseTextures = baseTextures;
        _creators = creators;
        _isNamespaced = isNamespaced;
        _baseScale = baseScale;
    }

    public function createMovie (symbol :String, cloneOf :Movie = null) :Movie {
        return Movie(createDisplayObject(symbol, cloneOf));
    }

    public function getSymbolCreator (symbol :String) :SymbolCreator {
        return requireSymbolCreator(symbol);
    }

    public function createImage (symbol :String, cloneOf :Image = null) :Image {
        const disp :DisplayObject = createDisplayObject(symbol, cloneOf);
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

    public function get isNamespaced () :Boolean {
        return _isNamespaced;
    }

    public function get baseTextures () :Vector.<Texture> {
        return _baseTextures;
    }

    public function get baseScale():Number {
        return _baseScale;
    }

    public function createDisplayObject (name :String, cloneOf :DisplayObject = null) :DisplayObject {
        checkNotDisposed();
        return requireSymbolCreator(cloneOf == null ? name : cloneOf.name).create(this, cloneOf);
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
    protected var _isNamespaced :Boolean;
    protected var _baseScale :Number;
}
}
