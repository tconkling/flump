function log() {
    var args = new Array();
    for (var ii = 0; ii < arguments.length; ii++) { args.push(arguments[ii]); }
    fl.trace(args.join(" "));
}

function pp(object, indent) {
    if (!indent) indent = '';
    var out = '';
    if (object.constructor == Array) {
        out += '[\n';
        for (var ii = 0; ii < object.length; ii++){
            out += "  " + indent + pp(object[ii], indent + "  ");
            if (ii < object.length - 1) out += ",";
            out += '\n';
        }
        out += indent + ']';
    } else if (object.constructor == Object) {
        out += '{\n';
            var first = true;
            for (var k in object) {
                if (!first) out += ",\n";
                first = false;
                out += "  " + indent + '"' + k + '": ' + pp(object[k], "  " + indent);
            }
            out += "\n" + indent + '}';
    } else if (object.constructor == String) {
        out += '"' + object + '"';
    } else {
        out += object;
    }
    return out;
}

var offsets = {
    forearmL: [-7.1, -1.65],
    handL: [-7.45, -3.7],
    neck: [-27.2, -22.1],
    bicepL: [-9.15, -9.1],
    chest: [-19.2, -29.55],
    belly: [-20.9, -25.3],
    skirtL: [-21.2, -13.75],
    skirtM: [-14.05, -5.6],
    skirtR: [-7.75, -15.15],
    thighL: [-7.3, 0.2],
    pelvis: [-15.85, -11.05],
    calfL: [-7.45, -7.95],
    footL: [-13.7, -3.35],
    thighR: [-9.05, -12],
    calfR: [-8, -7.6],
    footR: [-20, -4.25],
    forearmR: [-7.55, -2.25],
    handR: [-6.3, -2.8],
    bicepR: [-13.25, -9.15],
    head: [-24.45, -54.25],
    device: [-8.6, -4.65]
}

log("Processsing");
log("====================");
processAnimation(document.getTimeline());
log();

function processAnimation(timeline) {
    var frameCount = 0;

    var children = [];
    var anims = [];
    for (var lidx = 0; lidx < timeline.layerCount; lidx++) {
        var frame = timeline.layers[lidx].frames[0];
        if (!frame || !frame.elements) continue;
        if (frame.elements.length != 1) { log("Bad layer", lidx); return; }
        var el = frame.elements[0];
        if (el.libraryItem == null) continue;
        var name = timeline.layers[lidx].name;
        var anim = {
            keyframes: {
                ROTATION: [],
                X_LOCATION: [],
                Y_LOCATION: [],
                X_ORIGIN: [],
                Y_ORIGIN: [],
                X_SCALE: [],
                Y_SCALE: []
            }
        };
        anims.push(anim);

        var image = [];
        if (offsets.hasOwnProperty(name)) {
            image.push({ name: name + ".png",
            type: "Image",
            animations: { "default": {
                keyframes: {
                    X_ORIGIN: [{frame: 0, interp: "LINEAR", value: -offsets[name][0]}],
                    Y_ORIGIN: [{frame: 0, interp: "LINEAR", value: -offsets[name][1]}],
                    X_LOCATION: [],
                    Y_LOCATION: [],
                    ROTATION: []
                }
            }}});

        }
        children.push({
            name: timeline.layers[lidx].name,
            type: "Group",
            children: image,
            animations: { "default": anim }});
    }
    for (var fidx = 0; fidx < timeline.frameCount; fidx++) {
        for (var lidx = 0; lidx < timeline.layerCount; lidx++) {
            var frame = timeline.layers[lidx].frames[fidx];
            if (!frame || frame.startFrame != fidx) continue;
            var el = frame.elements[0];
            if (el.libraryItem == null) continue;
            var anim = anims[lidx];
            var name = timeline.layers[lidx].name;
            function update(field, value) {
                var vals = anim.keyframes[field];
                if (field == "ROTATION") {
                    vals = children[lidx].children[0];
                    if (vals === undefined) return;
                    vals = vals.animations["default"].keyframes.ROTATION;
                }
                if (vals.length > 0 && vals[vals.length - 1].value == value) return;
                vals.push({frame: fidx, interp: "LINEAR", value: value});
            }
            update("ROTATION", el.skewX * 0.0174532925);
            //update("X_LOCATION", -el.transformX - el.x);
            //update("Y_LOCATION", -el.transformY - el.y);
            update("X_ORIGIN", -el.x);
            update("Y_ORIGIN", -el.y);
            update("X_SCALE", el.scaleX);
            update("Y_SCALE", el.scaleY);
        }
    }
    writeFile('/Users/charlie/dev/papercut/src/main/resources/streetwalker/streetwalker.json', '{"children":' + pp(children) + "}");
}

function writeFile (filePath, fileContent)
{
    fl.trace("Exporting to file:\n" + filePath + "\n");
    //fl.trace(fileContent);
    var folder = filePath.substr(0, filePath.lastIndexOf("/"));
    var folderuri = convertToURI(folder);
    if (!FLfile.exists(folderuri)) {
        fl.trace("Creating directory: " + folderuri);
        if (!FLfile.createFolder(folderuri) || !FLfile.exists(folderuri)) {
            fl.trace("Error: Unable to create output directory: " + folder);
            return;
        }
    }
    if (FLfile.exists(filePath) && contains(FLfile.getAttributes(filePath), "R")) {
        fl.trace("\nERROR: " + path + " is marked as read-only.\n");
    } else {
        if (FLfile.write(convertToURI(filePath), fileContent)) {
            fl.trace("\nExport successful: " + filePath + "\n");
        } else {
            fl.trace("\nERROR: Export failed. Failed to write to:\n" + filePath + "\n\n");
        }
    }
}

function convertToURI (path) {
    var result = path;
    // Convert any Windows backslashes "\" to forward slashes "/"
    var reg = /\\/g;
    result = result.replace(reg, "/");

    // Convert any spaces
    reg = / /g;
    result = result.replace(reg, "%20");

    // Convert "C:" to "C|"
    if (result.charAt(1) == ":") {
        result = result.substr(0, 1) + "|" + result.substr(2);
    }

    // Now prepend the "file:///" uri prefix
    result = "file:///" + result;

    return result;
}

/**
 * Checks whether string s contains string sub.
 */
function contains (s, sub) { return s.indexOf(sub) != -1; }

function startsWith (s, prefix) { return s.indexOf(prefix) === 0; }
