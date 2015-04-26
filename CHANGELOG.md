Flump: Changelog
================

version 1.4 - 2015-04-25
------------------------

Runtime:
- License changed to ever-so-slightly more permissive MIT (from BSD)

Exporter:
- added: "Combine" project option. This lets you combine a project's output into a single texture atlas/JSON combo, which is especially useful for mobile games, where avoiding GPU state changes can result in much better performance. (Thanks, Nathan Curtis.)

* added: Mac command line exporting. There's a bash script in the Exporter's rsrc/ directory that launches Flump and exports the given .flump project, so Flump can be part of your automated build process. (Thanks, Nathan Curtis.)

* added: The "additionalScaleFactors" project setting is replaced with "scaleFactors." This allows you to, e.g., just export @2X textures without getting 1X textures as well. (Thanks, Nathan Curtis.)

* updated: Use the MaxRect algorithm for texture packing. This speeds up the export process a bit. (Thanks, matyasatfp.)


version 1.3 - 2014-02-08
------------------------

Runtime:
- new APIs: Movie.playChildrenOnly, Movie.stopAt, Movie.play
- updated: rather than adding and removing children from the display list, Layer toggles its
    childrens' visibility. This results in a reasonable performance increase, but is also a
    breaking change; please test your code accordingly! (thanks to @kpatelPro)
- fixed: support for Starling's `handleLostContext` functionality
- updated: build with ASC 2.0

Exporter:
- drop unmaintained com.threerings.aspirin dependency; replace with com.timconkling.aspire

version 1.2 - 2013-10-09
------------------------

Runtime:
- fixed: layers no longer display anything when the playhead moves past the end of their timelines
- updated: building against Starling 1.4
- updated: using 'react', instead of 'as3-signals', for signal dispatching (this is a minor breaking change to the API)
- updated: free up memory earlier and more frequently during loading
- various minor bugfixes and optimizations

Exporter:
- fixed: use proper export settings when generating preview atlases
- fixed: proper handling of filters at export time (from @kpatelPro)
- fixed: proper handling of "folder" layers (from @kpatelPro)
- updated: texture packing optimizations (from @kpatelPro)
- updated: better error messages

version 1.1 - 2013-05-30
------------------------

Runtime:
- added: ATF texture support
- added: MoviePlayer (automatic management of Movies on the display list)
- added: Library.getImageTexture
- fixed: don't fire label signals if updateFrame is interrupted
- fixed: various minor bugs
- added: texture mipmap generation options

Exporter:
- added: texture atlas optimization options
- added: texture bitmap data quality options
- added: "Export Modified" button
- updated: load images asynchronously
- fixed: catch and display errors that occur during publishing
