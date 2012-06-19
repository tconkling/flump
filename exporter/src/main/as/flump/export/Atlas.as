//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.IDataOutput;

import com.adobe.images.PNGEncoder;

import flump.SwfTexture;
import flump.mold.AtlasMold;
import flump.mold.AtlasTextureMold;

import com.threerings.util.Arrays;

public class Atlas
{
    // The empty border size around the right and bottom edges of each texture, to prevent bleeding
    public static const PADDING :int = 1;

    public var name :String;

    public function Atlas (name :String, w :int, h :int) {
        this.name = name;
        _width = w;
        _height = h;
        _mask = Arrays.create(_width * _height, false);
    }

    public function get area () :int { return _width * _height; }

    public function get filename () :String { return name + ".png"; }

    public function get used () :int {
        var used :int = 0;
        _nodes.forEach(function (n :Node, ..._) :void { used += n.bounds.width * n.bounds.height; });
        return used;
    }

    public function writePNG (bytes :IDataOutput) :void {
        var constructed :Sprite = new Sprite();
        _nodes.forEach(function (node :Node, ..._) :void {
            const tex :SwfTexture = node.texture;
            const bm :Bitmap = new Bitmap(node.texture.toBitmapData(), "auto", true);
            constructed.addChild(bm);
            bm.x = node.bounds.x;
            bm.y = node.bounds.y;
        });
        const bd :BitmapData =
            SwfTexture.renderToBitmapData(constructed, _width, _height);
        bytes.writeBytes(PNGEncoder.encode(bd));
    }

    public function toMold () :AtlasMold {
        const mold :AtlasMold = new AtlasMold();
        mold.file = name + ".png";
        _nodes.forEach(function (node :Node, ..._) :void {
            const tex :SwfTexture = node.texture;
            const texMold :AtlasTextureMold = new AtlasTextureMold();
            texMold.symbol = tex.symbol;
            texMold.bounds = new Rectangle(node.bounds.x, node.bounds.y, tex.w, tex.h);
            texMold.offset = new Point(tex.offset.x, tex.offset.y);
            texMold.md5 = tex.md5;
            mold.textures.push(texMold);
        });
        return mold;
    }


    // Try to place a texture in this atlas, return true if it fit
    public function place (tex :SwfTexture) :Boolean {
        var w :int = tex.w + PADDING;
        var h :int = tex.h + PADDING;
        if (w > _width || h > _height) {
            return false;
        }

        var found :Boolean = false;
        for (var yy :int = 0; yy < _height - h && !found; ++yy) {
            for (var xx :int = 0; xx <= _width - w; ++xx) {
                // if our right-most pixel is masked, jump ahead by that much
                if (maskAt(xx + w - 1, yy)) {
                    xx += w;
                    continue;
                }

                if (!isMasked(xx, yy, w, h)) {
                    _nodes.push(new Node(xx, yy, tex));
                    setMasked(xx, yy, w, h);
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
    protected var _mask :Array;
}
}

import flash.geom.Rectangle;

import flump.SwfTexture;

class Node
{
    public var bounds :Rectangle;
    public var texture :SwfTexture;

    public function Node (x :int, y :int, texture :SwfTexture) {
        this.texture = texture;
        this.bounds = new Rectangle(x, y, texture.w, texture.h);
    }
}
