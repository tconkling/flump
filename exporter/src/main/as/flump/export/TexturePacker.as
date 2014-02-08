//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import flash.display.StageQuality;

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
    public function optimizeForSpeed (val :Boolean) :TexturePacker { _optimizeForSpeed = val; return this; }
    public function quality (val :String) :TexturePacker { _quality = val; return this; }
    public function filenamePrefix (val :String) :TexturePacker { _filenamePrefix = val; return this; }

    public function createAtlases () :Vector.<Atlas> {
        return new PackerImpl(_lib, _baseScale, _scaleFactor, _borderSize,
            _maxAtlasSize, _optimizeForSpeed, _quality, _filenamePrefix).atlases;
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
    protected var _optimizeForSpeed :Boolean = false;
    protected var _quality :String = StageQuality.BEST;
}
}


import aspire.util.Comparators;
import aspire.util.Log;
import aspire.util.Preconditions;

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

class PackerImpl
{
    public const atlases :Vector.<Atlas> = new <Atlas>[];

    public function PackerImpl (lib :XflLibrary, baseScale :Number, scaleFactor :int,
        textureBorderSize :int, maxAtlasSize :int, optimizeForSpeed :Boolean,
        quality :String, filenamePrefix :String) {

        _textureBorderSize = textureBorderSize;
        _maxAtlasSize = maxAtlasSize;
        _optimizeForSpeed = optimizeForSpeed;
        _quality = quality;

        var scale :Number = baseScale * scaleFactor;

        for each (var tex :XflTexture in lib.textures) {
            _unpacked.push(SwfTexture.fromTexture(lib.swf, tex, quality, scale));
        }
        for each (var movie :MovieMold in lib.movies) {
            if (!movie.flipbook) continue;
            for each (var kf :KeyframeMold in movie.layers[0].keyframes) {
                _unpacked.push(SwfTexture.fromFlipbook(lib, movie, kf.index, quality, scale));
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
                scaleFactor,
                quality));
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
        log.info("Finished packing", "quality", quality, "scale", scale, "time", totalTime / 1000);
    }

    // Estimate the optimal size for the next atlas
    protected function findOptimalSize () :Point {
        if (_optimizeForSpeed) {
            // Go ahead and use the largest possible atlas, extra space will be trimmed by AtlasImpl
            // when rendering to a bitmap
            return new Point(_maxAtlasSize, _maxAtlasSize);
        }

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

    /** Returns the smallest number >= n that is a power of two. */
    public static function nextPowerOfTwo (n :int) :int {
        var p :int = 1;
        while (p < n) p *= 2;
        return p;
    }

    protected var _textureBorderSize :int;
    protected var _maxAtlasSize :int;
    protected var _optimizeForSpeed :Boolean;
    protected var _quality :String;

    protected const _unpacked :Vector.<SwfTexture> = new <SwfTexture>[];

    private static const log :Log = Log.getLog(PackerImpl);
}

class AtlasImpl
    implements Atlas
{
    public var name :String;

    public function AtlasImpl (name :String, w :int, h :int, borderSize :int, scaleFactor :int, quality :String) {
        this.name = name;
        _width = w;
        _height = h;
        _borderSize = borderSize;
        _mask = new BitmapData(_width, _height, true, 0);
        _mask.lock()
        _scaleFactor = scaleFactor;
        _quality = quality;
    }

    public function get area () :int { return _width * _height; }

    public function get scaleFactor () :int { return _scaleFactor; }

    public function get quailty () :String { return _quality; }

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
            var collapsedBounds :Rectangle = new Rectangle();
            _nodes.forEach(function (node :Node, ..._) :void {
                const tex :SwfTexture = node.texture;
                const bm :Bitmap = new Bitmap(node.texture.toBitmapData(_borderSize), "auto", true);
                constructed.addChild(bm);
                bm.x = node.paddedBounds.x;
                bm.y = node.paddedBounds.y;
                collapsedBounds = collapsedBounds.union(node.paddedBounds);
            });
            _bitmapData = Util.renderToBitmapData(constructed,
                PackerImpl.nextPowerOfTwo(collapsedBounds.x + collapsedBounds.width),
                PackerImpl.nextPowerOfTwo(collapsedBounds.y + collapsedBounds.height),
                quailty);
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

    protected static var _isMaskedPoint:Point = new Point();
    protected static var _isMaskedRect:Rectangle = new Rectangle();
    protected function isMasked (x :int, y :int, w :int, h :int) :Boolean {
        _isMaskedRect.setTo(x, y, w, h);
        return _mask.hitTest(_isMaskedPoint, 1, _isMaskedRect);
    }

    protected static var _setMaskedRect:Rectangle = new Rectangle();
    protected function setMasked (x :int, y :int, w: int, h :int) :void {
        _setMaskedRect.setTo(x, y, w, h);
        _mask.fillRect(_setMaskedRect, 0xffffffff);
    }

    protected function maskAt (xx :int, yy :int) :Boolean {
        return _mask.getPixel32(xx, yy) != 0;
    }

    protected var _nodes :Array = [];
    protected var _width :int;
    protected var _height :int;
    protected var _borderSize :int;
    protected var _mask :BitmapData;
    protected var _bitmapData :BitmapData;
    protected var _scaleFactor :int;
    protected var _quality :String;
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
