//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.display.BitmapData;
import flash.display.Sprite;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.IDataOutput;

import com.adobe.images.PNGEncoder;

import flump.SwfTexture;
import flump.mold.AtlasMold;
import flump.mold.AtlasTextureMold;

public class Atlas
{
    // The empty border size around the right and bottom edges of each texture, to prevent bleeding
    public static const PADDING :int = 1;

    public var name :String;
    public var targetDevice :DeviceType;

    public function Atlas (name :String, targetDevice :DeviceType, w :int, h :int) {
        this.name = name;
        this.targetDevice = targetDevice;

        _root = new Node(0, 0, w, h);
    }

    // Try to place a texture in this atlas, return true if it fit
    public function place (texture :SwfTexture) :Boolean {
        var node :Node = _root.search(texture.w + PADDING, texture.h + PADDING);
        if (node == null) {
            return false;
        }

        node.texture = texture;
        return true;
    }

    public function get area () :int { return _root.bounds.width * _root.bounds.height; }

    public function get used () :int {
        var used :int = 0;
        _root.forEach(function (n :Node) :void { used += n.bounds.width * n.bounds.height; });
        return used;
    }

    public function writePNG (bytes :IDataOutput) :void {
        var constructed :Sprite = new Sprite();
        _root.forEach(function (node :Node) :void {
            var tex :SwfTexture = node.texture;
            var sprite :Sprite = new Sprite();
            sprite.scaleX = sprite.scaleY = tex.scale;
            constructed.addChild(tex.holder);
            tex.holder.x = node.bounds.x;
            tex.holder.y = node.bounds.y;
        });
        var bd :BitmapData =
            SwfTexture.renderToBitmapData(constructed, _root.bounds.width, _root.bounds.height);
        bytes.writeBytes(PNGEncoder.encode(bd));
    }

    public function get fileName () :String { return name + targetDevice.extension + ".png"; }

    public function publish (dir :File) :void {
        var fs :FileStream = new FileStream();
        fs.open(dir.resolvePath(fileName), FileMode.WRITE);
        writePNG(fs);
        fs.close();
    }

    public function toMold () :AtlasMold {
        const mold :AtlasMold = new AtlasMold();
        mold.file = name + ".png";
        _root.forEach(function (node :Node) :void {
            var tex :SwfTexture = node.texture;
            const texMold :AtlasTextureMold = new AtlasTextureMold();
            texMold.name = tex.symbol;
            texMold.bounds = new Rectangle(node.bounds.x, node.bounds.y, tex.w, tex.h);
            texMold.offset = new Point(tex.offset.x, tex.offset.y);
            texMold.md5 = tex.md5;
            mold.textures.push(texMold);
        });
        return mold;
    }

    public function toJSON (_:*) :Object { return toMold().toJSON(null); }

    protected var _root :Node;
}
}

import flash.geom.Rectangle;

import flump.SwfTexture;

// A node in a k-d tree
class Node
{
    // The bounds of this node (and its children)
    public var bounds :Rectangle;

    // The texture that is placed here, if any. Implies that this is a leaf node
    public var texture :SwfTexture;

    // This node's two children, if any
    public var left :Node;
    public var right :Node;

    public function Node (x :int, y :int, w :int, h :int)
    {
        bounds = new Rectangle(x, y, w, h);
    }

    // Find a free node in this tree big enough to fit an area, or null
    public function search (w :int, h :int) :Node
    {
        if (texture != null) {
            // There's already a texture here, terminate
            return null;
        }

        if (left != null && right != null) {
            // Try to fit it into this node's children
            var descendent :Node = left.search(w, h);
            if (descendent == null) {
                descendent = right.search(w, h);
            }
            return descendent;

        } else {
            if (bounds.width == w && bounds.height == h) {
                // This node is a perfect size, no need to subdivide
                return this;
            }
            if (bounds.width < w || bounds.height < h) {
                // This will never fit, terminate
                return null;
            }

            var dw :Number = bounds.width - w;
            var dh :Number = bounds.height - h;

            if (dw > dh) {
                left = new Node(bounds.x, bounds.y, w, bounds.height);
                right = new Node(bounds.x + w, bounds.y, dw, bounds.height);

            } else {
                left = new Node(bounds.x, bounds.y, bounds.width, h);
                right = new Node(bounds.x, bounds.y + h, bounds.width, dh);
            }

            return left.search(w, h);
        }
    }

    // Iterate over all nodes with textures in this tree
    public function forEach (fn :Function /* Node -> void */) :void {
        if (texture != null) {
            fn(this);
        }

        if (left != null && right != null) {
            left.forEach(fn);
            right.forEach(fn);
        }
    }
}
