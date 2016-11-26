Installation
============
copy/paste the folders in Configuration folder in the Flash/Animation Configuration folder (ex on windows: C:\Users\%userName%\AppData\Local\Adobe\Animate CC 2015.2\en_EN\Configuration)

Usage
=====
1) Open the Persistant Data panel in Flash/Animate : File > Window > Extensions > Persistent Data
2) Select an instance in a layer of a MovieClip setup for Flump
3) roll over the panel and add the data you want
4) save the .FLA (or .XFL)

check the examples in panel.PNG and panel2.PNG

Build
=====
- Use the Flump version that supports customData
- generate the atlas
--> the JSON description contains the persistentData

check the example in json.PNG

Runtime
=======
You need a runtime that implements this feature

At this moment there's only a beta version of flump-pixi-runtime (haxe) that supports it.

example of the method in the FlumpMovie class:

	public function getCustomData (layerId:String, keyframeIndex:UInt = 0): Dynamic {
		var layer = symbol.getLayer(layerId);
		if(layer == null) throw("Layer " + layerId + " does not exist.");
		var keyframe = symbol.getLayer(layerId).getKeyframeForFrame(keyframeIndex);
		if (keyframe == null) throw("Keyframe does not exist at index " + keyframeIndex);
		return keyframe.persistentData;
	}


check the result in Console.PNG
