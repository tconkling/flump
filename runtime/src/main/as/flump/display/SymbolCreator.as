package flump.display {

import starling.display.DisplayObject;

internal interface SymbolCreator {
    function create (library :Library) :DisplayObject;
}
}
