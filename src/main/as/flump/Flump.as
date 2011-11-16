package flump {

import flash.display.MovieClip;
import flash.filesystem.FileMode;
import flash.filesystem.File;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;
import com.adobe.images.PNGEncoder;
import flash.display.BitmapData;
import flash.display.Bitmap;
import flash.geom.Rectangle;
import com.threerings.flashbang.resource.SwfResource;
import com.threerings.flashbang.resource.ResourceManager;
import com.threerings.util.F;
import flash.display.LoaderInfo;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.sampler.Sample;
import flash.sampler.StackFrame;
import flash.sampler.getSamples;
import flash.sampler.pauseSampling;
import flash.sampler.clearSamples;
import flash.sampler.startSampling;
import flash.sampler.stopSampling;
import flash.utils.Timer;
import flash.events.TimerEvent;
import flash.ui.Keyboard;

public class Flump extends Sprite
{
    public function Flump ()
    {
        _rsrc.registerDefaultResourceTypes();
        addEventListener(Event.ADDED_TO_STAGE, F.callbackOnce(addedToStage));
    }

    protected function addedToStage () :void
    {
        _rsrc.queueResourceLoad("swf", "pant", { embeddedClass: PANT});
        _rsrc.queueResourceLoad("swf", "hat", { embeddedClass: HAT});
        _rsrc.queueResourceLoad("swf", "top", { embeddedClass: TOP});
        _rsrc.queueResourceLoad("swf", "hed", { embeddedClass: HED});
        _rsrc.queueResourceLoad("swf", "sho", { embeddedClass: SHO});
        _rsrc.queueResourceLoad("swf", "base", { embeddedClass: BASE});
        _rsrc.loadQueuedResources(resourcesLoaded);
    }

    protected function resourcesLoaded () :void
    {
        F.forEach(layers, export);
        trace("{\n    " + _offsets.join(",\n    ") + "\n}");
    }

    protected function export (layer :String) :void
    {
        var theClass :Class;
        for each (var resource :String in resources) {
            theClass= SwfResource.getSwf(_rsrc, resource).getClass(layer + "_class");
            if (theClass != null) break;
        }
        if (theClass == null) { trace("skipping " + layer); return; }


        const holder :Sprite = new Sprite();
        const child :Sprite = Sprite(new theClass());
        holder.addChild(child);
        const bounds :Rectangle = child.getBounds(holder);
        if (bounds.width == 0 || bounds.height == 0) { trace("invisible " + layer); return; }
        if (_renames.hasOwnProperty(layer)) layer = _renames[layer];
        child.x = -bounds.x;
        child.y = -bounds.y;
        _offsets.push(layer + ": [" + bounds.x + ', ' + bounds.y + "]");

        const bd :BitmapData = new BitmapData(bounds.width, bounds.height, true);
        // Clear bitmapdata's default white background with a transparent one
        bd.fillRect(new Rectangle(0, 0, bounds.width, bounds.height), 0);
        bd.draw(holder);
        var fs :FileStream = new FileStream();
        fs.open(new File("/Users/charlie/dev/flump/" + layer + ".png"), FileMode.WRITE);
        fs.writeBytes(PNGEncoder.encode(bd));
        fs.close();
    }

    protected const _offsets :Array = [];

    protected const _rsrc :ResourceManager = new ResourceManager();
    protected const _renames :Object = {"container_device_a": "device", "container_head_a": "head"};

    protected const layers :Array = ["forearmL", "handL", "head", "neck", "bicepL", "scarfB",
        "chest", "belly", "skirtL", "skirtM", "skirtR", "thighL", "pelvis", "calfL", "footL",
        "thighR", "calfR", "footR", "forearmR", "handR", "device", "bicepR", "tails", "hairB",
        "container_head_a", "container_device_a", "shadow"];

    protected const resources :Array = ["pant", "hat", "top", "hed", "sho", "base"];

    [Embed(source="/../swfresources/avatar/HAT_001.swf", mimeType="application/octet-stream")]
    protected const HAT :Class;
    [Embed(source="/../swfresources/avatar/PNT_001.swf", mimeType="application/octet-stream")]
    protected const PANT :Class;
    [Embed(source="/../swfresources/avatar/TOP_001.swf", mimeType="application/octet-stream")]
    protected const TOP :Class;
    [Embed(source="/../swfresources/avatar/HED_001.swf", mimeType="application/octet-stream")]
    protected const HED :Class;
    [Embed(source="/../swfresources/avatar/SHO_001.swf", mimeType="application/octet-stream")]
    protected const SHO :Class;
    [Embed(source="/../swfresources/avatar/male_player_base.swf", mimeType="application/octet-stream")]
    protected const BASE :Class;
}
}
