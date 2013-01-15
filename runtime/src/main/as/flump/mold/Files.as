//
// Flump - Copyright 2013 Flump Authors

package flump.mold {

public class Files
{
    /**
     * Returns the substring composed of the characters after the last '.' in the supplied string.
     * The substring will be converted to lowercase.
     */
    public static function getDotSuffix (filename :String) :String
    {
        // is there a dot?
        var ix :int = filename.lastIndexOf(".");
        if (ix >= 0) {
            var ext :String = filename.substr(ix + 1);
            // is there a ?foo=bar component?
            ix = ext.indexOf('?');
            if (ix > 0) {
                ext = ext.substring(0, ix);
            }
            return ext.toLowerCase();
        }
        return "";
    }

    /**
     * Returns the substring composed of the characters before the last '.' in the supplied string.
     */
    public static function stripDotSuffix (filename :String) :String
    {
        var ix :int = filename.lastIndexOf(".");
        return (ix >= 0 ? filename.substr(0, ix) : filename);
    }

    /**
     * Returns the substring composed of the characters after the last path separator
     * in the supplied string.
     */
    public static function stripPath (filename :String, separator :String = "/") :String
    {
        var ix :int = filename.lastIndexOf(separator);
        return (ix >= 0 ? filename.substr(ix + 1) : filename);
    }

    /**
     * Strips the path and dot-suffix from the given filename.
     */
    public static function stripPathAndDotSuffix (filename :String, separator :String = "/") :String
    {
        return stripDotSuffix(stripPath(filename, separator));
    }
}

}
