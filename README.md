# Flump

Flump reads specially-constructed `.fla` and `.xfl` files saved by Flash and extracts animations and
textures to allow them to be recreated in the GPU via [Starling](http://www.starling-framework.org/)
or [Sparrow](http://www.sparrow-framework.org/). Animations created in Flump's style will use far
less texture memory per frame of animation than an equivalent flipbook animation, allowing for more
and more expressive animations on mobile platforms.

# Creating a movie for Flump

1. [Download and install](https://github.com/downloads/threerings/flump/flump-exporter.air) the .air app
2. Create a document in Flash Professional saved as `.xfl`
3. Create a new item in the library and draw a shape in its canvas
4. Right-click on the item, select its properties, mark it as exported for ActionScript, and change
   its base class to `flash.display.Sprite`
5. Create a second item in the library, and drag the first into it.
6. Add additional frames in the second item, and create a classic tween moving the first item around
   in those frames.
7. Save the file and publish it as a swf.
8. Open the Flump .air app and change its import directory to the directory containing the `.xfl` and
   `.swf` files. The `.xfl` file should appear in the list of source files.
9. Select the `.xfl` file and click 'Preview'. The tween you created in step 6 should start playing
   back in a preview window.

# Details of Flump's conversion

This walks through Flump's process when it exports a single .xfl/.swf file combo.

### Texture creation

For each item in the document's library that is exported for ActionScript and extends
`flash.display.Sprite`, Flump creates a texture. To do so, it instantiates the library's exported
symbol from the `.swf` file and renders it to a bitmap.

All of the created bitmaps for a Flash document are packed into texture atlases, and xml is
generated to map between a texture's symbol and its location in the bitmap.

### Animation creation

For each item in the document's library that extends `flash.display.MovieClip` and isn't a flipbook (explained below), Flump creates an animation. It checks that for all layers and keyframes, each used symbol is either a texture, an animation, or a flipbook. Flump animations can only be constructed from the flump types.

### Flipbook creation

For animations that only contain a few frames, a flipbook may be more appropriate. To create one,
add a new item to the library and name the first layer in the created item `flipbook`. When
exporting, flump will create a bitmap for each keyframe in the flipbook layer. In playback, flump
will display those bitmaps at the same timing.

# Bugs

To get AIR to report errors, you need to run Flump with the AIR debugger (adl).
Assuming you have the free [Flex SDK](http://www.adobe.com/devnet/flex/flex-sdk-download.html) and [ant](http://ant.apache.org/) installed on your machine:

1. Build the flump runtime

        flump/runtime$ ant -Dflexsdk.dir=/path/to/flex maven-deploy

2. Build the flump exporter

        flump/exporter$ ant -Dflexsdk.dir=/path/to/flex swf

3. Run the flump exporter

        flump/exporter$ /path/to/flex/bin/adl etc/airdesc.xml dist
