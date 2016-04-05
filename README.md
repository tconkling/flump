# Flump

Flump reads specially-constructed `.fla` and `.xfl` files saved by Flash and extracts animations and
textures to allow them to be recreated in the GPU. Animations created in Flump's style will use far
less texture memory per frame of animation than an equivalent flipbook animation, allowing for more
expressive animations on mobile platforms. Runtimes have been written for [Starling], [Sparrow],
[Flambe], [PlayN], and [StageXL].

[Starling]: https://github.com/threerings/flump/tree/master/runtime
[Sparrow]: https://github.com/threerings/betwixt
[Flambe]: https://github.com/aduros/flambe
[PlayN]: https://github.com/threerings/tripleplay
[StageXL]: http://www.stagexl.org/index.html

# Creating a movie for Flump

1. [Install the latest version of Adobe AIR](http://get.adobe.com/air/).
1. [Install the Flump AIR app](https://github.com/threerings/flump/releases/latest).
2. Create a `.fla` in Flash CS 5, 5.5, or 6.
3. Create a new item in the library and draw a shape in its canvas.
4. Right-click on the item, select its properties, tick the **Export for ActionScript** and
   **Export in frame 1** checkboxes and change its base class to `flash.display.Sprite`.
5. Create a second item in the library, and drag the first into it.
6. Add additional frames in the second item, and create a classic tween moving the first item around
   in those frames.
6. Set the **Export for ActionScript** and **Export in frame 1** properties for the second item. Leave its base class as `flash.display.MovieClip`.
7. Save the file and publish it as a swf.
8. Open the Flump app and change its import directory to the directory containing the `.fla` and
   `.swf` files. The `.fla` file should appear in the list of source files.
9. Select the `.fla` file and click 'Preview'. The tween you created in step 6 should start playing
   back in a preview window.

# Details of Flump's conversion

This walks through Flump's process when it exports a single .fla/.swf file combo.

### Texture creation

For each item in the document's library that is exported for ActionScript and extends
`flash.display.Sprite`, Flump creates a texture. To do so, it instantiates the library's exported
symbol from the `.swf` file and renders it to a bitmap.

All of the created bitmaps for a Flash document are packed into texture atlases, and xml is
generated to map between a texture's symbol and its location in the bitmap.

### Animation creation

For each item in the document's library that extends `flash.display.MovieClip` and isn't a flipbook
(explained below), Flump creates an animation. It checks that for all layers and keyframes, each
used symbol is either a texture, an animation, or a flipbook. Flump animations can only be
constructed from the flump types.

### Flipbook creation

For animations that only contain a few frames, a flipbook may be more appropriate. To create one,
add a new item to the library and name the first layer in the created item `flipbook`. When
exporting, flump will create a bitmap for each keyframe in the flipbook layer. In playback, flump
will display those bitmaps at the same timing.

### Compatibility

Flump works with Flash CS 5 and later

# Precompiled binaries

[Get them here](https://github.com/threerings/flump/releases/latest)

# Building

You will need these dependencies to build Flump:

* [Flex SDK 4.6](http://www.adobe.com/devnet/flex/flex-sdk-download.html).

* [AIR SDK](https://www.adobe.com/devnet/air/air-sdk-download.html). 

* [AIR SDK with Flex Support](https://www.adobe.com/devnet/air/air-sdk-download.html) You'll also need to download the version of the AIR SDK that comes *without* the new compiler (links near the bottom of that page) and [follow the instructions here to overlay it on the Flex SDK](http://helpx.adobe.com/x-productkb/multi/how-overlay-air-sdk-flex-sdk.html)

* [Ant](http://ant.apache.org/)

1. Build the flump runtime

        flump/runtime$ ant -Dairsdk.dir=/path/to/air maven-deploy

2. Build the flump exporter

        flump/exporter$ ant -Dflexsdk.dir=/path/to/flex swf
        
3. Build the flump demo

        flump/demo ant -Dairsdk.dir=/path/to/air

4. To get AIR to report errors, run Flump with the AIR debugger (adl):

        flump/exporter$ /path/to/air/bin/adl etc/airdesc.xml dist
        
# Runtimes

A list of known Flump runtime implementations for different languages and frameworks:

* [Flump (Starling/AS3)](https://github.com/tconkling/flump) (the reference runtime, contained here)
* [Flambe (Haxe)](https://github.com/aduros/flambe)
* [pixi-flump-runtime (Haxe/PixiJs)](https://github.com/jackwlee01/pixi-flump-runtime)
* [StageXL_Flump](https://github.com/bp74/StageXL_Flump) (Dart / HTML5 / WebGL / Canvas)
* [Betwixt (Sparrow/Objective-C)](https://github.com/threerings/betwixt) (no longer maintained)
