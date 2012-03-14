//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.display.Sprite;
import flash.filesystem.File;

import flump.SwfTexture;

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

    public function publish (dir :File) :void {
        var constructed :Sprite = new Sprite();
        _root.forEach(function (node :Node) :void {
            var tex :SwfTexture = node.texture;
            var sprite :Sprite = new Sprite();
            sprite.scaleX = sprite.scaleY = tex.scale;
            constructed.addChild(tex.holder);
            tex.holder.x = node.bounds.x;
            tex.holder.y = node.bounds.y;
        });
        PngPublisher.publish(dir.resolvePath(name + targetDevice.extension + ".png"),
            _root.bounds.width, _root.bounds.height, constructed);
    }

    public function toJSON (_:*) :Object {
        var json :Object = {
            file: name + ".png",
            textures: []
        };
        _root.forEach(function (node :Node) :void {
            var tex :SwfTexture = node.texture;
            var textureJson :Object = {
                name: tex.symbol,
                rect: [ node.bounds.x, node.bounds.y, tex.w, tex.h ]
            };
            if (tex.offset.x != 0 || tex.offset.y != 0) {
                textureJson.offset = [ tex.offset.x, tex.offset.y ];
            }
            if (tex.md5 != null) {
                textureJson.md5 = tex.md5;
            }
            json.textures.push(textureJson);
        });
        return json;
    }

    public function toXML () :XML
    {
        var json :Object = toJSON(null);

        var xml :XML = <atlas
            file={json.file}
        />;
        for each (var tex :Object in json.textures) {
            var textureXml :XML = <texture
                name={tex.name}
                rect={tex.rect}
            />;
            if (tex.offset != null) {
                textureXml.@offset = tex.offset;
            }
            if (tex.md5 != null) {
                textureXml.@md5 = tex.md5;
            }
            xml.appendChild(textureXml);
        }
        return xml;
    }

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
