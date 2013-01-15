//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flump.xfl.XflLibrary;

/**
 * Creates texture atlases from an XflLibrary
 */
public class TexturePacker
{
    public static function withLib (lib :XflLibrary) :TexturePacker { return new TexturePacker(lib); }

    public function baseScale (val :Number) :TexturePacker { _baseScale = val; return this; }
    public function scaleFactor (val :int) :TexturePacker {  _scaleFactor = val; return this; }
    public function borderSize (val :int) :TexturePacker { _borderSize = val; return this; }
    public function maxAtlasSize (val :int) :TexturePacker { _maxAtlasSize = val; return this; }
    public function filenamePrefix (val :String) :TexturePacker { _filenamePrefix = val; return this; }

    public function createAtlases () :Vector.<Atlas> {
        return new PackerImpl(_lib, _baseScale, _scaleFactor, _borderSize,
            _maxAtlasSize, _filenamePrefix).atlases;
    }

    /** @private */
    public function TexturePacker (lib :XflLibrary) {
        _lib = lib;
    }

    protected var _lib :XflLibrary;
    protected var _baseScale :Number = 1;
    protected var _scaleFactor :int = 1;
    protected var _borderSize :int = 1;
    protected var _maxAtlasSize :int = 2048;
    protected var _filenamePrefix :String = "";
}
}


import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.getTimer;

import flump.SwfTexture;
import flump.Util;
import flump.export.Atlas;
import flump.mold.AtlasMold;
import flump.mold.AtlasTextureMold;
import flump.mold.KeyframeMold;
import flump.mold.MovieMold;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

import com.threerings.util.Arrays;
import com.threerings.util.Comparators;
import com.threerings.util.Log;
import com.threerings.util.Preconditions;

class PackerImpl
{
    public const atlases :Vector.<Atlas> = new <Atlas>[];

    public function PackerImpl (lib :XflLibrary, baseScale :Number, scaleFactor :int,
        textureBorderSize :int, maxAtlasSize :int, filenamePrefix :String) {

        _maxAtlasSize = maxAtlasSize;
        _textureBorderSize = textureBorderSize;

        var scale :Number = baseScale * scaleFactor;

        for each (var tex :XflTexture in lib.textures) {
            _unpacked.push(SwfTexture.fromTexture(lib.swf, tex, scale));
        }
        for each (var movie :MovieMold in lib.movies) {
            if (!movie.flipbook) continue;
            for each (var kf :KeyframeMold in movie.layers[0].keyframes) {
                _unpacked.push(SwfTexture.fromFlipbook(lib, movie, kf.index, scale));
            }
        }
        _unpacked.sort(Comparators.createReverse(Comparators.createFields(["a", "w", "h"])));

        var start :int = flash.utils.getTimer();
        while (_unpacked.length > 0) {
            // Add a new atlas
            const size :Point = findOptimalSize();
            atlases.push(new AtlasImpl(
                filenamePrefix + "atlas" + atlases.length,
                size.x, size.y,
                textureBorderSize,
                scaleFactor));
            var hasEmptyAtlas :Boolean = true;

            // Try to pack each texture into any atlas
            for (var ii :int = 0; ii < _unpacked.length; ++ii) {
                var unpacked :SwfTexture = _unpacked[ii];
                var w :int = unpacked.w + (_textureBorderSize * 2);
                var h :int = unpacked.h + (_textureBorderSize * 2);

                if (w > _maxAtlasSize || h > _maxAtlasSize) {
                    throw new Error("Too large to fit in an atlas: '" + unpacked.symbol + "' (" +
                        w + "x" + h + ")");
                }

                for each (var atlas :AtlasImpl in atlases) {
                    // TODO(bruno): Support rotated textures?
                    if (atlas.place(unpacked)) {
                        hasEmptyAtlas = false;
                        _unpacked.splice(ii--, 1);
                        break;
                    }
                }
            }

            Preconditions.checkState(_unpacked.length == 0 || !hasEmptyAtlas,
                "Texture won't fit in newly-created atlas?");
        }

        var totalTime :int = flash.utils.getTimer() - start;
        log.info("Finished packing", "scale", scale, "time", totalTime / 1000);
    }

    // Estimate the optimal size for the next atlas
    protected function findOptimalSize () :Point {
        var area :int = 0;
        var maxW :int = 0;
        var maxH :int = 0;

        for each (var tex :SwfTexture in _unpacked) {
            const w :int = tex.w + (_textureBorderSize * 2);
            const h :int = tex.h + (_textureBorderSize * 2);
            area += w * h;
            maxW = Math.max(maxW, w);
            maxH = Math.max(maxH, h);
        }

        const size :Point = new Point(nextPowerOfTwo(maxW), nextPowerOfTwo(maxH));

        // Double the area until it's big enough
        while (size.x * size.y < area) {
            if (size.x < size.y) size.x *= 2;
            else size.y *= 2;
        }

        size.x = Math.min(size.x, _maxAtlasSize);
        size.y = Math.min(size.y, _maxAtlasSize);

        return size;
    }

    protected static function nextPowerOfTwo (n :int) :int {
        var p :int = 1;
        while (p < n) p *= 2;
        return p;
    }

    protected var _maxAtlasSize :int;
    protected var _textureBorderSize :int;

    protected const _unpacked :Vector.<SwfTexture> = new <SwfTexture>[];

    private static const log :Log = Log.getLog(PackerImpl);
}

class AtlasImpl
    implements Atlas
{
    public var name :String;

    public function AtlasImpl (name :String, w :int, h :int, borderSize :int, scaleFactor :int) {
        this.name = name;
        _width = w;
        _height = h;
        _borderSize = borderSize;
        _mask = Arrays.create(_width * _height, false);
        _scaleFactor = scaleFactor;
    }

    public function get area () :int { return _width * _height; }

    public function get scaleFactor () :int { return _scaleFactor; }

    public function get filename () :String { return name + AtlasMold.scaleFactorSuffix(_scaleFactor) + ".png"; }

    public function get used () :int {
        var used :int = 0;
        _nodes.forEach(function (n :Node, ..._) :void {
            used += n.paddedBounds.width * n.paddedBounds.height;
        });
        return used;
    }

    public function toMold () :AtlasMold {
        const mold :AtlasMold = new AtlasMold();
        mold.file = this.filename;
        _nodes.forEach(function (node :Node, ..._) :void {
            const tex :SwfTexture = node.texture;
            const texMold :AtlasTextureMold = new AtlasTextureMold();
            texMold.symbol = tex.symbol;
            texMold.bounds = new Rectangle(node.bounds.x, node.bounds.y, tex.w, tex.h);
            texMold.origin = new Point(tex.origin.x, tex.origin.y);
            mold.textures.push(texMold);
        });
        return mold;
    }

    public function toBitmap () :BitmapData {
        if (_bitmapData == null) {
            var constructed :Sprite = new Sprite();
            _nodes.forEach(function (node :Node, ..._) :void {
                const tex :SwfTexture = node.texture;
                const bm :Bitmap = new Bitmap(node.texture.toBitmapData(_borderSize), "auto", true);
                constructed.addChild(bm);
                bm.x = node.paddedBounds.x;
                bm.y = node.paddedBounds.y;
            });
            _bitmapData = Util.renderToBitmapData(constructed, _width, _height);
        }
        return _bitmapData;
    }

    // Try to place a texture in this atlas, return true if it fit
    public function place (tex :SwfTexture) :Boolean {
        var w :int = tex.w + (_borderSize * 2);
        var h :int = tex.h + (_borderSize * 2);
        if (w > _width || h > _height) {
            return false;
        }

        var found :Boolean = false;
        for (var yy :int = 0; yy <= _height - h && !found; ++yy) {
            for (var xx :int = 0; xx <= _width - w; ++xx) {
                // if our right-most pixel is masked, jump ahead by that much
                if (maskAt(xx + w - 1, yy)) {
                    xx += w;
                    continue;
                }

                if (!isMasked(xx, yy, w, h)) {
                    var node :Node = new Node(xx, yy, _borderSize, tex);
                    _nodes.push(node);
                    setMasked(node.paddedBounds.x, node.paddedBounds.y,
                        node.paddedBounds.width, node.paddedBounds.height);
                    found = true;
                    break;
                }
            }
        }

        return found;
    }

    protected function isMasked (x :int, y :int, w :int, h :int) :Boolean {
        var xMax :int = x + w - 1;
        var yMax :int = y + h - 1;
        // fail fast on extents
        if (maskAt(x, y) || maskAt(x, yMax) || maskAt(xMax, y) || maskAt(xMax, yMax)) {
            return true;
        }

        for (var yy :int = y + 1; yy < yMax; ++yy) {
            for (var xx :int = x + 1; xx < xMax; ++xx) {
                if (maskAt(xx, yy)) {
                    return true;
                }
            }
        }
        return false;
    }

    protected function setMasked (x :int, y :int, w: int, h :int) :void {
        for (var yy :int = y; yy < y + h; ++yy) {
            for (var xx :int = x; xx < x + w; ++xx) {
                _mask[(yy * _width) + xx] = true;
            }
        }
    }

    protected function maskAt (xx :int, yy :int) :Boolean {
        return _mask[(yy * _width) + xx];
    }

    protected var _nodes :Array = [];
    protected var _width :int;
    protected var _height :int;
    protected var _borderSize :int;
    protected var _mask :Array;
    protected var _bitmapData :BitmapData;
    protected var _scaleFactor :int;
}

class Node
{
    public var bounds :Rectangle;
    public var paddedBounds :Rectangle;
    public var texture :SwfTexture;

    public function Node (x :int, y :int, borderSize :int, texture :SwfTexture) {
        this.texture = texture;
        this.bounds = new Rectangle(x + borderSize, y + borderSize, texture.w, texture.h);
        this.paddedBounds = new Rectangle(x, y,
            texture.w + (borderSize * 2),
            texture.h + (borderSize * 2));
    }
}
