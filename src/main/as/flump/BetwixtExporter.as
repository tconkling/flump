//
// Flump - Copyright 2012 Three Rings Design

package flump {

import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;

import flump.xfl.XflAnimation;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

public class BetwixtExporter
{
    public function export (lib :XflLibrary, source :File, exportDir :File) :void {
        const dest :File = exportDir.resolvePath(lib.name + ".xml");
        const out :FileStream = new FileStream();
        out.open(dest, FileMode.WRITE);
        out.writeUTFBytes("<resources>\n");
        for each (var anim :XflAnimation in lib.animations) {
            out.writeUTFBytes('  <movie name="' + anim.name + '" group="">\n');

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
                ".png' xOffset='" + tex.offset.x + "' yOffset='" + tex.offset.y + "'/>\n");
        }

        out.writeUTFBytes("</resources>");
        dest

    }
}
}
