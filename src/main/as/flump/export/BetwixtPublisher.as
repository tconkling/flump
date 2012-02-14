//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;

import flump.bytesToXML;
import flump.xfl.XflAnimation;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

import com.threerings.util.Log;
import com.threerings.util.Map;
import com.threerings.util.Maps;
import com.threerings.util.XmlUtil;

public class BetwixtPublisher
{
    public static function makeExportLocation(lib :XflLibrary, exportDir :File) :File {
        return exportDir.resolvePath(lib.location + ".xml");
    }

    public static function modified(lib :XflLibrary, exportDir :File) :Boolean {
        const exportLoc :File = makeExportLocation(lib, exportDir);
        if (!exportLoc.exists) return true;

        const libMd5s :Map = Maps.newMapOf(String);
        for each (var anim :XflAnimation in lib.animations) libMd5s.put(anim.name, anim.md5);
        for each (var tex :XflTexture in lib.textures) libMd5s.put(tex.name, tex.md5);

        const exportMd5s :Map = Maps.newMapOf(String);
        var export :FileStream = new FileStream();
        export.open(exportLoc, FileMode.READ);
        var exportBytes :ByteArray = new ByteArray();
        export.readBytes(exportBytes);
        for each (var resource :XML in bytesToXML(exportBytes).elements()) {
            exportMd5s.put(XmlUtil.getStringAttr(resource, "name"),
                XmlUtil.getStringAttr(resource, "md5"));
        }
        return !exportMd5s.equals(libMd5s);
    }

    public static function export (lib :XflLibrary, source :File, exportDir :File) :void {
        const dest :File = exportDir.resolvePath(lib.location + ".xml");
        const out :FileStream = new FileStream();
        out.open(dest, FileMode.WRITE);
        out.writeUTFBytes("<resources>\n");
        for each (var anim :XflAnimation in lib.animations) {
            out.writeUTFBytes('  <movie name="' + anim.name + '" md5="' + anim.md5 + '">\n');

            var animFile :File = source.resolvePath("LIBRARY/" + anim.name + ".xml");
            var copy :FileStream = new FileStream();
            copy.open(animFile, FileMode.READ);
            var bytes :ByteArray = new ByteArray();
            copy.readBytes(bytes);
            out.writeBytes(bytes);
            out.writeUTFBytes('\n  </movie>\n');
        }
        for each (var tex :XflTexture in lib.textures) {
            out.writeUTFBytes("  <texture name='" + tex.name + "' filename='" + tex.symbol +
                ".png' xOffset='" + tex.offset.x + "' yOffset='" + tex.offset.y +
                "' md5='" + tex.md5 + "'/>\n");
        }

        out.writeUTFBytes("</resources>");
    }
    private static const log :Log = Log.getLog(BetwixtPublisher);
}
}
