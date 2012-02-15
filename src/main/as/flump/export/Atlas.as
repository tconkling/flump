//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.display.Sprite;
import flash.filesystem.File;
import flash.geom.Rectangle;

public class Atlas
{
    public var name :String;
    public var w :int, h :int, id :int;
    public var bins :Vector.<Rectangle> = new Vector.<Rectangle>();
    public const textures :Vector.<PackedTexture> = new Vector.<PackedTexture>();

    public function Atlas(name :String, w :int, h :int) {
        this.name = name;
        this.w = w;
        this.h = h;
        bins.push(new Rectangle(0, 0, w, h));
    }

    public function place (tex :PackedTexture, target :Rectangle, rotated :Boolean) :void {
        tex.atlasX = target.x;
        tex.atlasY = target.y;
        tex.atlasRotated = rotated;
        textures.push(tex);
        trace("Packer " + tex);
        var used :Rectangle =
            new Rectangle(tex.atlasX, tex.atlasY, rotated ? tex.h : tex.w, rotated ? tex.w : tex.h);
        const newBins :Vector.<Rectangle> = new Vector.<Rectangle>();
        for each (var bin :Rectangle in bins) {
            for each (var newBin :Rectangle in subtract(bin, used)) {
                newBins.push(newBin);
            }
        }
        bins = newBins;
    }

    public function subtract (space :Rectangle, area :Rectangle) :Vector.<Rectangle> {
        const left :Vector.<Rectangle> = new Vector.<Rectangle>();
        if (space.x < area.x) {
            left.push(new Rectangle(space.x, space.y, area.left - space.x, space.height));
        }
        if (space.right > area.right) {
            left.push(new Rectangle(area.right, space.y, space.right - area.right, space.height));
        }
        if (space.y < area.y) {
            left.push(new Rectangle(space.x, space.y, space.width, area.top - space.y));
        }
        if (space.bottom > area.bottom) {
            left.push(new Rectangle(space.x, area.bottom, space.width, space.bottom - area.bottom));
        }
        return left;
    }

    public function publish (dir :File) :void {
        var constructed :Sprite = new Sprite();
        for each (var tex :PackedTexture in textures) {
            constructed.addChild(tex.holder);
            tex.holder.x = tex.atlasX;
            tex.holder.y = tex.atlasY;
        }
        PngPublisher.publish(dir.resolvePath(name + ".png"), w, h, constructed);
    }

    public function toXml () :String {
        var xml :String = "<atlas name='" + name + "' filename='" + name + ".png'>\n";
        for each (var tex :PackedTexture in textures) {
            xml += "  <texture name='" + tex.name + "' xOffset='" + tex.offset.x +
                "' yOffset='" + tex.offset.y + "' md5='" + tex.md5 +
                "' xAtlas='" + tex.atlasX + "' yAtlas='" + tex.atlasY +
                "' wAtlas='" + tex.w + "' hAtlas='" + tex.h + "'/>\n";
        }
        return xml + "</atlas>\n";
    }
}
}
