package flump.display {

import starling.display.DisplayObject;

public interface SymbolCreator {
    function create (library :Library) :DisplayObject;
}
}
