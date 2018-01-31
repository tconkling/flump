Flump: Changelog
================
version 1.5.6 - 2018-01-31
--------------------------
Exporter:
- Added "baseScale" property to root node of exported property file

Runtime:
- Possibility to use "baseScale" property, which was defined in exporter
- new setter added to LibraryLoader:
setScaleTexturesToOrigin (scaleTexturesToOrigin :Boolean):LibraryLoader


version 1.5.3 - 2017-08-23
--------------------------
Exporter:
- Better error messages for movie parse failures
- Regenerate signing certificate

Runtime:
- Build against Starling 2.2

If you're upgrading from a previous version of the Flump Export tool, you'll likely need to completely uninstall your previous version first, because the signing certificate has been changed.


version 1.5.1 - 2016-09-30
--------------------------
Exporter:
- Fixed: Don't pad single textures that fit exactly in an atlas
- Added: AutomaticExporter: '--unmodified' flag to force exporting regardless of 'modified' status

Runtime:
- Added: Movie.setLayerEnabled()
- Fixed: proper handling of Movie.removeChild()
- Changed: Build against Starling 2.1


version 1.5.0 - 2016-06-12
--------------------------
Runtime:
- Changed: build against Starling 2.0.1


version 1.4.3 - 2016-06-07
--------------------------
Runtime:
- Fixed: MoviePlayer better detects whether it should manage a Movie or not
- Added: Library.getSymbolCreator()


version 1.4.2 - 2016-04-28
--------------------------
Exporter:
- Changed: command-line exporter doesn't publish "combined" formats if they haven't been modified

Runtime:
- Added: Movie.recursiveGoTo()
- Changed: build against Starling 1.8


version 1.4.1 - 2015-05-14
--------------------------

Exporter:
- Fixed: "export combined" projects with varying FLA framerates properly report errors now. (A regression in 1.4 caused any project with varying framerates to simply fail to load.)


version 1.4 - 2015-04-25
------------------------

Runtime:
- License changed to ever-so-slightly more permissive MIT (from BSD)

Exporter:
- added: "Combine" project option. This lets you combine a project's output into a single texture atlas/JSON combo, which is especially useful for mobile games, where avoiding GPU state changes can result in much better performance. (Thanks, Nathan Curtis.)

- added: Mac command line exporting. There's a bash script in the Exporter's rsrc/ directory that launches Flump and exports the given .flump project, so Flump can be part of your automated build process. (Thanks, Nathan Curtis.)

- added: The "additionalScaleFactors" project setting is replaced with "scaleFactors." This allows you to, e.g., just export @2X textures without getting 1X textures as well. (Thanks, Nathan Curtis.)

- updated: Use the MaxRect algorithm for texture packing. This speeds up the export process a bit. (Thanks, matyasatfp.)


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
