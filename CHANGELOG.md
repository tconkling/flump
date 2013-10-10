Flump: Changelog
================

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
