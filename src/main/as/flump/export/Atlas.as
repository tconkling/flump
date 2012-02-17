//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.display.Sprite;
import flash.filesystem.File;
import flash.geom.Rectangle;

import flump.SwfTexture;

import com.threerings.util.Map;
import com.threerings.util.Maps;

public class Atlas
{
    public var name :String;
    public var w :int, h :int, id :int;
    public var bins :Vector.<Rectangle> = new Vector.<Rectangle>();
    public const textures :Vector.<SwfTexture> = new Vector.<SwfTexture>();

    public function Atlas(name :String, w :int, h :int) {
        this.name = name;
        this.w = w;
        this.h = h;
        bins.push(new Rectangle(0, 0, w, h));
    }

    public function place (tex :SwfTexture, target :Rectangle, rotated :Boolean) :void {
        _locs.put(tex, {x: target.x, y: target.y, rotated: rotated});
        textures.push(tex);
        trace("Packer " + tex);
        var used :Rectangle =
            new Rectangle(target.x, target.y, rotated ? tex.h : tex.w, rotated ? tex.w : tex.h);
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
        for each (var tex :SwfTexture in textures) {
            constructed.addChild(tex.holder);
            var loc :Object = _locs.get(tex);
            tex.holder.x = loc.x;
            tex.holder.y = loc.y;
        }
        PngPublisher.publish(dir.resolvePath(name + ".png"), w, h, constructed);
    }

    public function toXml () :String {
        var xml :String = "<atlas name='" + name + "' filename='" + name + ".png'>\n";
        for each (var tex :SwfTexture in textures) {
            var loc :Object = _locs.get(tex);
            xml += "  <texture name='" + tex.name + "' xOffset='" + tex.offset.x +
                "' yOffset='" + tex.offset.y + "' md5='" + tex.md5 +
                "' xAtlas='" + loc.x + "' yAtlas='" + loc.y +
                "' wAtlas='" + tex.w + "' hAtlas='" + tex.h + "'/>\n";
        }
        return xml + "</atlas>\n";
    }

    protected const _locs :Map = Maps.newMapOf(SwfTexture);//{x :int, y :int, rotated :Boolean}
}
}
