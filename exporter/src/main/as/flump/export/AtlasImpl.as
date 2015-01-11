package flump.export {

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.geom.Point;
import flash.geom.Rectangle;

import flump.SwfTexture;
import flump.Util;

import flump.mold.AtlasMold;
import flump.mold.AtlasTextureMold;

public class AtlasImpl implements Atlas
{
    public var name :String;

    public function AtlasImpl (name :String, w :int, h :int, borderSize :int, scaleFactor :int, quality :String) {
        this.name = name;
        _width = w;
        _height = h;
        _borderSize = borderSize;
        _mask = new BitmapData(_width, _height, true, 0);
        _mask.lock();
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
                    Util.nextPowerOfTwo(collapsedBounds.x + collapsedBounds.width),
                    Util.nextPowerOfTwo(collapsedBounds.y + collapsedBounds.height),
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
}

import flash.geom.Rectangle;

import flump.SwfTexture;

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

