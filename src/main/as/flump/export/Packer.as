//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Rectangle;

import com.adobe.images.PNGEncoder;

import com.threerings.util.Comparators;

public class Packer
{

    public static const BIN_SIZES :Vector.<int> = new <int>[8, 16, 32, 64, 128, 256, 512, 1024];

    public function Packer (toPack :Vector.<DisplayObject>) {
        for each (var img :DisplayObject in toPack) _unpacked.push(new Texture(img));
        _unpacked.sort(Comparators.createReverse(Comparators.createFields(["a", "w", "h"])));
        var minBin :int = findOptimalMinBin();
        _atlases.push(new Atlas(minBin, minBin));
        while (_unpacked.length > 0) pack(_unpacked.shift());
    }

    public function publish (dir :File) :void {
        for (var ii :int = 0; ii < _atlases.length; ii++) {
            var atlas :Atlas = _atlases[ii];
            var constructed :Sprite = new Sprite();
            for each (var tex :Texture in atlas.textures) {
                constructed.addChild(tex.holder);
                tex.holder.x = tex.atlasX;
                tex.holder.y = tex.atlasY;
            }
            const bd :BitmapData = new BitmapData(atlas.w, atlas.h, true);
            // Clear bitmapdata's default white background with a transparent one
            bd.fillRect(new Rectangle(0, 0, atlas.w, atlas.h), 0);
            bd.draw(constructed);
            var fs :FileStream = new FileStream();
            fs.open(dir.resolvePath(ii + ".png"), FileMode.WRITE);
            fs.writeBytes(PNGEncoder.encode(bd));
            fs.close();
        }
    }

    protected function pack (tex :Texture) :void {
        for each (var atlas :Atlas in _atlases) {
            for each (var bin :Rectangle in atlas.bins) {
                if (tex.w <= bin.width && tex.h <= bin.height) {
                    atlas.place(tex, bin, false);
                    return;
                } else if (tex.h <= bin.width && tex.w <= bin.height) {
                    atlas.place(tex, bin, true);
                    return;
                }
            }
        }
        // TODO - allocate another atlas
        throw new Error("Doesn't fit " + tex);
    }

    protected function findOptimalMinBin () :int {
        var area :int = 0;
        var maxExtent :int = 0;
        for each (var tex :Texture in _unpacked) {
            area += tex.a;
            maxExtent = Math.max(maxExtent, tex.w, tex.h);
        }
        for each (var size :int in BIN_SIZES) {
            if (size >= maxExtent && size * size >= area) return size;
        }
        return BIN_SIZES[BIN_SIZES.length -1];
    }

    protected const _unpacked :Vector.<Texture> = new Vector.<Texture>();
    protected const _atlases :Vector.<Atlas> = new Vector.<Atlas>();
}
}

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.geom.Point;
import flash.geom.Rectangle;

class Texture {

    public const holder :Sprite = new Sprite();
    public var offset :Point;
    public var w :int, h :int, a :int;
    public var atlasX :int, atlasY :int;
    public var atlasRotated :Boolean;

    public function Texture (image :DisplayObject) {
        holder.addChild(image);
        const bounds :Rectangle = image.getBounds(holder);
        offset = new Point(bounds.x, bounds.y);
        w = Math.ceil(bounds.width);
        h = Math.ceil(bounds.height);
        a = w * h;
    }

    public function toString () :String {
        return "a " + a + " w " + w + " h " + h + " atlas " + atlasX + ", " + atlasY;
    }

}

import flash.geom.Rectangle;

class Atlas {
    public var w :int, h :int;
    public var bins :Vector.<Rectangle> = new Vector.<Rectangle>();
    public const textures :Vector.<Texture> = new Vector.<Texture>();

    public function Atlas(w :int, h :int) {
        this.w = w;
        this.h = h;
        bins.push(new Rectangle(0, 0, w, h));
    }

    public function place (tex :Texture, target :Rectangle, rotated :Boolean) :void {
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
}
