/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.util.MimeTypeUtils;


import hunt.collection;
import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.text;
import hunt.util.AcceptMimeType;
import hunt.util.MimeType;
import hunt.util.ObjectUtils;

import std.algorithm;
import std.array;
import std.concurrency : initOnce;
import std.container.array;
import std.conv;
import std.file;
import std.path;
import std.range;
import std.stdio;
import std.string;
import std.uni;


/**
*/
class MimeTypeUtils {

    // Allow installing resources into a shared dir
    private static string getResourcePrefix() {
        mixin("string resourcePrefix = \"@DATA_PREFIX@\";");
        // We don't want meson to replace the CONF_PREFIX here too,
        // otherwise this would always be true.
        if (resourcePrefix == join(["@DATA", "_PREFIX@"])) {
            return dirName(thisExePath()) ~ "/resources";
        } else {
            return buildPath(resourcePrefix, "resources");
        }
    }

    // private __gshared static ByteBuffer[string] TYPES; // = new ArrayTrie<>(512);
    private static Map!(string, string) __dftMimeMap() {
        __gshared Map!(string, string) m;
        return initOnce!m({
            Map!(string, string) _m = new HashMap!(string, string)();
            auto resourcePath = getResourcePrefix();
            string resourceName = buildPath(resourcePath, "mime.properties");
            loadMimeProperties(resourceName, _m);
            return _m;
        }());
    }

    private __gshared Map!(string, string) _inferredEncodings;
    private __gshared Map!(string, string) _assumedEncodings;

    private static void initializeEncodingsMap() {
        __gshared bool _isEncodingsLoaded = false;
        initOnce!(_isEncodingsLoaded)({
            _inferredEncodings = new HashMap!(string, string)();
            _assumedEncodings = new HashMap!(string, string)();

            foreach (MimeType type ; MimeType.values) {
                CACHE[type.toString()] = type;
                // TYPES[type.toString()] = type.asBuffer();

                auto charset = type.toString().indexOf(";charset=");
                if (charset > 0) {
                    string alt = type.toString().replace(";charset=", "; charset=");
                    CACHE[alt] = type;
                    // TYPES[alt] = type.asBuffer();
                }

                if (type.isCharsetAssumed())
                    _assumedEncodings.put(type.asString(), type.getCharsetString());
            }

            auto resourcePath = getResourcePrefix();
            string resourceName = buildPath(resourcePath, "encoding.properties");
            loadEncodingProperties(resourceName);
            return true;
        }());
    }

    __gshared MimeType[string] CACHE; 


    private static void loadMimeProperties(string fileName, Map!(string, string) m) {
        if(!exists(fileName)) {
            version(HUNT_DEBUG) warningf("File does not exist: %s", fileName);
            return;
        }

        void doLoad() {
            version(HUNT_DEBUG) tracef("loading MIME properties from: %s", fileName);
            try {
                File f = File(fileName, "r");
                scope(exit) f.close();
                string line;
                int count = 0;
                while((line = f.readln()) !is null) {
                    string[] parts = split(line, "=");
                    if(parts.length < 2) continue;

                    count++;
                    string key = parts[0].strip().toLower();
                    string value = normalizeMimeType(parts[1].strip());
                    // trace(key, " = ", value);
                    m.put(key, value);
                }

                if (m.size() == 0) {
                    warningf("Empty mime types at %s", fileName);
                } else if (m.size() < count) {
                    warningf("Duplicate or null mime-type extension in resource: %s", fileName);
                }            
            } catch(Exception ex) {
                warningf(ex.toString());
            }
        }

        doLoad();
        // import std.parallelism;
        // auto t = task(&doLoad);
        // t.executeInNewThread();
    }

    private static void loadEncodingProperties(string fileName) {
        if(!exists(fileName)) {
            version(HUNT_DEBUG) warningf("File does not exist: %s", fileName);
            return;
        }

        version(HUNT_DEBUG) tracef("loading MIME properties from: %s", fileName);
        try {
            File f = File(fileName, "r");
            scope(exit) f.close();
            string line;
            int count = 0;
            while((line = f.readln()) !is null) {
                string[] parts = split(line, "=");
                if(parts.length < 2) continue;

                count++;
                string t = parts[0].strip();
                string charset = parts[1].strip();
                version(HUNT_DEBUG) trace(t, " = ", charset);
                if(charset.startsWith("-"))
                    _assumedEncodings.put(t, charset[1..$]);
                else
                    _inferredEncodings.put(t, charset);
            }

            if (_inferredEncodings.size() == 0) {
                warningf("Empty encodings at %s", fileName);
            } else if (_inferredEncodings.size() + _assumedEncodings.size() < count) {
                warningf("Null or duplicate encodings in resource: %s", fileName);
            }            
        } catch(Exception ex) {
            warningf(ex.toString());
        }
    }

    /**
     * Constructor.
     */
    this() {
    }

    Map!(string, string) getMimeMap() {
        if(_mimeMap is null)
            _mimeMap = new HashMap!(string, string)();
        return _mimeMap;
    }

    private Map!(string, string) _mimeMap; 

    /**
     * @param mimeMap A Map of file extension to mime-type.
     */
    void setMimeMap(Map!(string, string) mimeMap) {
        _mimeMap.clear();
        if (mimeMap !is null) {
            foreach (string k, string v ; mimeMap) {
                _mimeMap.put(std.uni.toLower(k), normalizeMimeType(v));
            }
        }
    }

    /**
     * Get the MIME type by filename extension.
     * Lookup only the static default mime map.
     *
     * @param filename A file name
     * @return MIME type matching the longest dot extension of the
     * file name.
     */
    static string getDefaultMimeByExtension(string filename) {
        string type = null;

        if (filename != null) {
            ptrdiff_t i = -1;
            while (type == null) {
                i = filename.indexOf(".", i + 1);

                if (i < 0 || i >= filename.length)
                    break;

                string ext = std.uni.toLower(filename[i + 1 .. $]);
                if (type == null)
                    type = __dftMimeMap().get(ext);
            }
        }

        if (type == null) {
            if (type == null)
                type = __dftMimeMap().get("*");
        }

        return type;
    }

    /**
     * Get the MIME type by filename extension.
     * Lookup the content and static default mime maps.
     *
     * @param filename A file name
     * @return MIME type matching the longest dot extension of the
     * file name.
     */
    string getMimeByExtension(string filename) {
        string type = null;

        if (filename != null) {
            ptrdiff_t i = -1;
            while (type == null) {
                i = filename.indexOf(".", i + 1);

                if (i < 0 || i >= filename.length)
                    break;

                string ext = std.uni.toLower(filename[i + 1 .. $]);
                if (_mimeMap !is null && _mimeMap.containsKey(ext))
                    type = _mimeMap.get(ext);
                if (type == null && __dftMimeMap.containsKey(ext))
                    type = __dftMimeMap.get(ext);
            }
        }

        if (type == null) {
            if (_mimeMap !is null && _mimeMap.containsKey("*"))
                type = _mimeMap.get("*");
            if (type == null && __dftMimeMap.containsKey("*"))
                type = __dftMimeMap.get("*");
        }

        return type;
    }

    /**
     * Set a mime mapping
     *
     * @param extension the extension
     * @param type      the mime type
     */
    void addMimeMapping(string extension, string type) {
        _mimeMap.put(std.uni.toLower(extension), normalizeMimeType(type));
    }

    static Set!string getKnownMimeTypes() {
        auto hs = new HashSet!(string)();
        foreach(v ; __dftMimeMap.byValue())
            hs.add(v);
        return hs;
    }

    private static string normalizeMimeType(string type) {
        MimeType t = CACHE.get(type, null);
        if (t !is null)
            return t.asString();

        return std.uni.toLower(type);
    }

    static string getCharsetFromContentType(string value) {
        if (value == null)
            return null;
        int end = cast(int)value.length;
        int state = 0;
        int start = 0;
        bool quote = false;
        int i = 0;
        for (; i < end; i++) {
            char b = value[i];

            if (quote && state != 10) {
                if ('"' == b)
                    quote = false;
                continue;
            }

            if (';' == b && state <= 8) {
                state = 1;
                continue;
            }

            switch (state) {
                case 0:
                    if ('"' == b) {
                        quote = true;
                        break;
                    }
                    break;

                case 1:
                    if ('c' == b) state = 2;
                    else if (' ' != b) state = 0;
                    break;
                case 2:
                    if ('h' == b) state = 3;
                    else state = 0;
                    break;
                case 3:
                    if ('a' == b) state = 4;
                    else state = 0;
                    break;
                case 4:
                    if ('r' == b) state = 5;
                    else state = 0;
                    break;
                case 5:
                    if ('s' == b) state = 6;
                    else state = 0;
                    break;
                case 6:
                    if ('e' == b) state = 7;
                    else state = 0;
                    break;
                case 7:
                    if ('t' == b) state = 8;
                    else state = 0;
                    break;

                case 8:
                    if ('=' == b) state = 9;
                    else if (' ' != b) state = 0;
                    break;

                case 9:
                    if (' ' == b)
                        break;
                    if ('"' == b) {
                        quote = true;
                        start = i + 1;
                        state = 10;
                        break;
                    }
                    start = i;
                    state = 10;
                    break;

                case 10:
                    if (!quote && (';' == b || ' ' == b) ||
                            (quote && '"' == b))
                        return StringUtils.normalizeCharset(value, start, i - start);
                    break;

                default: break;
            }
        }

        if (state == 10)
            return StringUtils.normalizeCharset(value, start, i - start);

        return null;
    }

    /**
     * Access a mutable map of mime type to the charset inferred from that content type.
     * An inferred encoding is used by when encoding/decoding a stream and is
     * explicitly set in any metadata (eg Content-MimeType).
     *
     * @return Map of mime type to charset
     */
    static Map!(string, string) getInferredEncodings() {
        initializeEncodingsMap();
        return _inferredEncodings;
    }

    /**
     * Access a mutable map of mime type to the charset assumed for that content type.
     * An assumed encoding is used by when encoding/decoding a stream, but is not
     * explicitly set in any metadata (eg Content-MimeType).
     *
     * @return Map of mime type to charset
     */
    static Map!(string, string) getAssumedEncodings() {
        initializeEncodingsMap();
        return _assumedEncodings;
    }

    static string getCharsetInferredFromContentType(string contentType) {
        return getInferredEncodings().get(contentType);
    }

    static string getCharsetAssumedFromContentType(string contentType) {
        return getAssumedEncodings().get(contentType);
    }

    static string getContentTypeWithoutCharset(string value) {
        int end = cast(int)value.length;
        int state = 0;
        int start = 0;
        bool quote = false;
        int i = 0;
        StringBuilder builder = null;
        for (; i < end; i++) {
            char b = value[i];

            if ('"' == b) {
                quote = !quote;

                switch (state) {
                    case 11:
                        builder.append(b);
                        break;
                    case 10:
                        break;
                    case 9:
                        builder = new StringBuilder();
                        builder.append(value, 0, start + 1);
                        state = 10;
                        break;
                    default:
                        start = i;
                        state = 0;
                }
                continue;
            }

            if (quote) {
                if (builder !is null && state != 10)
                    builder.append(b);
                continue;
            }

            switch (state) {
                case 0:
                    if (';' == b)
                        state = 1;
                    else if (' ' != b)
                        start = i;
                    break;

                case 1:
                    if ('c' == b) state = 2;
                    else if (' ' != b) state = 0;
                    break;
                case 2:
                    if ('h' == b) state = 3;
                    else state = 0;
                    break;
                case 3:
                    if ('a' == b) state = 4;
                    else state = 0;
                    break;
                case 4:
                    if ('r' == b) state = 5;
                    else state = 0;
                    break;
                case 5:
                    if ('s' == b) state = 6;
                    else state = 0;
                    break;
                case 6:
                    if ('e' == b) state = 7;
                    else state = 0;
                    break;
                case 7:
                    if ('t' == b) state = 8;
                    else state = 0;
                    break;
                case 8:
                    if ('=' == b) state = 9;
                    else if (' ' != b) state = 0;
                    break;

                case 9:
                    if (' ' == b)
                        break;
                    builder = new StringBuilder();
                    builder.append(value, 0, start + 1);
                    state = 10;
                    break;

                case 10:
                    if (';' == b) {
                        builder.append(b);
                        state = 11;
                    }
                    break;

                case 11:
                    if (' ' != b)
                        builder.append(b);
                    break;
                
                default: break;
            }
        }
        if (builder is null)
            return value;
        return builder.toString();

    }

    static string getContentTypeMIMEType(string contentType) {
        if (contentType.empty) 
            return null;

        // parsing content-type
        string[] strings = StringUtils.split(contentType, ";");
        return strings[0];
    }

    static List!string getAcceptMIMETypes(string accept) {
        if(accept.empty) 
            new EmptyList!string(); // Collections.emptyList();

        List!string list = new ArrayList!string();
        // parsing accept
        string[] strings = StringUtils.split(accept, ",");
        foreach (string str ; strings) {
            string[] s = StringUtils.split(str, ";");
            list.add(s[0].strip());
        }
        return list;
    }

    static AcceptMimeType[] parseAcceptMIMETypes(string accept) {

        if(accept.empty) 
            return [];

        string[] arr = StringUtils.split(accept, ",");
        return apply(arr);
    }

    private static AcceptMimeType[] apply(string[] stream) {

        Array!AcceptMimeType arr;

        foreach(string s; stream) {
            string type = strip(s);
            if(type.empty) continue;
            string[] mimeTypeAndQuality = StringUtils.split(type, ';');
            AcceptMimeType acceptMIMEType = new AcceptMimeType();
            
            // parse the MIME type
            string[] mimeType = StringUtils.split(mimeTypeAndQuality[0].strip(), '/');
            string parentType = mimeType[0].strip();
            string childType = mimeType[1].strip();
            acceptMIMEType.setParentType(parentType);
            acceptMIMEType.setChildType(childType);
            if (parentType == "*") {
                if (childType == "*") {
                    acceptMIMEType.setMatchType(AcceptMimeMatchType.ALL);
                } else {
                    acceptMIMEType.setMatchType(AcceptMimeMatchType.CHILD);
                }
            } else {
                if (childType == "*") {
                    acceptMIMEType.setMatchType(AcceptMimeMatchType.PARENT);
                } else {
                    acceptMIMEType.setMatchType(AcceptMimeMatchType.EXACT);
                }
            }

            // parse the quality
            if (mimeTypeAndQuality.length > 1) {
                string q = mimeTypeAndQuality[1];
                string[] qualityKV = StringUtils.split(q, '=');
                acceptMIMEType.setQuality(to!float(qualityKV[1].strip()));
            }
            arr.insertBack(acceptMIMEType);
        }

        for(size_t i=0; i<arr.length-1; i++) {
            for(size_t j=i+1; j<arr.length; j++) {
                AcceptMimeType a = arr[i];
                AcceptMimeType b = arr[j];
                if(b.getQuality() > a.getQuality()) {   // The greater quality is first.
                    arr[i] = b; arr[j] = a;
                }
            }
        }

        return arr.array();
    }
}
