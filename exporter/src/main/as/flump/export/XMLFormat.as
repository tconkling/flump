//
// Flump - Copyright 2012 Three Rings Design

package flump.export {

import flash.utils.ByteArray;
import flash.utils.IDataOutput;

import flump.bytesToXML;
import flump.mold.MovieMold;
import flump.xfl.XflLibrary;

import com.threerings.util.XmlUtil;

public class XMLFormat extends Format
{
    public function XMLFormat () {
        super("resources.xml");
    }

    override public function extractMd5 (metadata :ByteArray) :String {
        return bytesToXML(metadata).@md5;
    }

    override public function publish(out :IDataOutput, lib :XflLibrary, movies :Vector.<MovieMold>,
packers :Vector.<Packer>, authoredDevice :DeviceType) :void {
        var xml :XML = <resources md5={lib.md5}/>;
        var prefix :String = lib.location + "/";
        for each (var movie :MovieMold in movies) {
            var movieXml :XML = movie.toXML();
            movieXml.@authoredDevice = authoredDevice.name();
            movieXml.@name = prefix + movieXml.@name;
            for each (var kf :XML in movieXml..kf) {
                if (XmlUtil.hasAttr(kf, "ref")) {
                    kf.@ref = prefix + kf.@ref;
                }
            }
            xml.appendChild(movieXml);
        }
        var groupsXml :XML = <textureGroups/>;
        xml.appendChild(groupsXml);
        for each (var packer :Packer in packers) {
            var groupXml :XML = <textureGroup target={packer.targetDevice}/>;
            groupsXml.appendChild(groupXml);
            for each (var atlas :Atlas in packer.atlases) {
                groupXml.appendChild(atlas.toMold().toXML());
            }
        }
        for each (var texture :XML in groupsXml..texture) {
            texture.@name = prefix + texture.@name;
        }
        out.writeUTFBytes(xml.toString());
    }
}
}
