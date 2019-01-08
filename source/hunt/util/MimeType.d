module hunt.util.MimeType;

import hunt.util.AcceptMimeType;

import hunt.collection;
import hunt.logging;

import hunt.Charset;
import hunt.exception;
import hunt.text;
import hunt.util.traits;

import std.algorithm;
import std.array;
import std.container.array;
import std.conv;
import std.file;
import std.path;
import std.range;
import std.stdio;
import std.string;
import std.uni;

class MimeType {
    /**
	 * A string equivalent of {@link MimeType#ALL}.
	 */
	enum string ALL_VALUE = "*/*";

	/**
	 * A string equivalent of {@link MimeType#APPLICATION_JSON}.
	 */
	enum string APPLICATION_JSON_VALUE = "application/json";    
    
	/**
	 * A string equivalent of {@link MimeType#APPLICATION_OCTET_STREAM}.
	 */
	enum string APPLICATION_OCTET_STREAM_VALUE = "application/octet-stream";

	/**
	 * A string equivalent of {@link MimeType#APPLICATION_XML}.
	 */
	enum string APPLICATION_XML_VALUE = "application/xml";

	/**
	 * A string equivalent of {@link MimeType#IMAGE_GIF}.
	 */
	enum string IMAGE_GIF_VALUE = "image/gif";

	/**
	 * A string equivalent of {@link MimeType#IMAGE_JPEG}.
	 */
	enum string IMAGE_JPEG_VALUE = "image/jpeg";

	/**
	 * A string equivalent of {@link MimeType#IMAGE_PNG}.
	 */
	enum string IMAGE_PNG_VALUE = "image/png";

	/**
	 * A string equivalent of {@link MimeType#TEXT_HTML}.
	 */
	enum string TEXT_HTML_VALUE = "text/html";

	/**
	 * A string equivalent of {@link MimeType#TEXT_PLAIN}.
	 */
	enum string TEXT_PLAIN_VALUE = "text/plain";

	/**
	 * A string equivalent of {@link MimeType#TEXT_XML}.
	 */
	enum string TEXT_XML_VALUE = "text/xml";        

	/**
	 * Public constant mime type that includes all media ranges (i.e. "&#42;/&#42;").
	 */
	__gshared MimeType ALL;
    __gshared MimeType APPLICATION_JSON;
    __gshared MimeType APPLICATION_XML;
    __gshared MimeType APPLICATION_JSON_8859_1;
    __gshared MimeType APPLICATION_JSON_UTF_8;
    __gshared MimeType APPLICATION_OCTET_STREAM;

    __gshared MimeType FORM_ENCODED;

    __gshared MimeType IMAGE_GIF;
    __gshared MimeType IMAGE_JPEG;
    __gshared MimeType IMAGE_PNG;

    __gshared MimeType MESSAGE_HTTP;
    __gshared MimeType MULTIPART_BYTERANGES;

    __gshared MimeType TEXT_HTML;
    __gshared MimeType TEXT_PLAIN;
    __gshared MimeType TEXT_XML;
    __gshared MimeType TEXT_JSON;

    __gshared MimeType TEXT_HTML_8859_1;
    __gshared MimeType TEXT_HTML_UTF_8;

    __gshared MimeType TEXT_PLAIN_8859_1;
    __gshared MimeType TEXT_PLAIN_UTF_8;

    __gshared MimeType TEXT_XML_8859_1;
    __gshared MimeType TEXT_XML_UTF_8;

    __gshared MimeType TEXT_JSON_8859_1;
    __gshared MimeType TEXT_JSON_UTF_8;

    __gshared Array!MimeType values;

    shared static this() {

        ALL = new MimeType(ALL_VALUE);
        
        APPLICATION_JSON = new MimeType(APPLICATION_JSON_VALUE, StandardCharsets.UTF_8);
        APPLICATION_JSON_8859_1 = new MimeType("application/json;charset=iso-8859-1", APPLICATION_JSON);
        APPLICATION_JSON_UTF_8 = new MimeType("application/json;charset=utf-8", APPLICATION_JSON);
        APPLICATION_OCTET_STREAM = new MimeType(APPLICATION_OCTET_STREAM_VALUE);
        APPLICATION_XML = new MimeType(APPLICATION_XML_VALUE, StandardCharsets.UTF_8);

        IMAGE_GIF = new MimeType(IMAGE_GIF_VALUE);
        IMAGE_JPEG = new MimeType(IMAGE_JPEG_VALUE);
        IMAGE_PNG = new MimeType(IMAGE_PNG_VALUE);

        MESSAGE_HTTP = new MimeType("message/http");
        MULTIPART_BYTERANGES = new MimeType("multipart/byteranges");

        TEXT_HTML = new MimeType(TEXT_HTML_VALUE);
        TEXT_PLAIN = new MimeType(TEXT_PLAIN_VALUE);
        TEXT_XML = new MimeType(TEXT_XML_VALUE);
        TEXT_JSON = new MimeType("text/json", StandardCharsets.UTF_8);

        TEXT_HTML_8859_1 = new MimeType("text/html;charset=iso-8859-1", TEXT_HTML);
        TEXT_HTML_UTF_8 = new MimeType("text/html;charset=utf-8", TEXT_HTML);

        TEXT_PLAIN_8859_1 = new MimeType("text/plain;charset=iso-8859-1", TEXT_PLAIN);
        TEXT_PLAIN_UTF_8 = new MimeType("text/plain;charset=utf-8", TEXT_PLAIN);

        TEXT_XML_8859_1 = new MimeType("text/xml;charset=iso-8859-1", TEXT_XML);
        TEXT_XML_UTF_8 = new MimeType("text/xml;charset=utf-8", TEXT_XML);

        TEXT_JSON_8859_1 = new MimeType("text/json;charset=iso-8859-1", TEXT_JSON);
        TEXT_JSON_UTF_8 = new MimeType("text/json;charset=utf-8", TEXT_JSON);

        values.insertBack(ALL);
        values.insertBack(APPLICATION_JSON);
        values.insertBack(APPLICATION_XML);
        values.insertBack(APPLICATION_JSON_8859_1);
        values.insertBack(APPLICATION_JSON_UTF_8);
        values.insertBack(APPLICATION_OCTET_STREAM);
        
        values.insertBack(IMAGE_GIF);
        values.insertBack(IMAGE_JPEG);
        values.insertBack(IMAGE_PNG);

        values.insertBack(MESSAGE_HTTP);
        values.insertBack(MULTIPART_BYTERANGES);
        
        values.insertBack(TEXT_HTML);
        values.insertBack(TEXT_PLAIN);
        values.insertBack(TEXT_XML);
        values.insertBack(TEXT_JSON);
        values.insertBack(TEXT_HTML_8859_1);
        values.insertBack(TEXT_HTML_UTF_8);
        values.insertBack(TEXT_PLAIN_8859_1);
        values.insertBack(TEXT_PLAIN_UTF_8);
        values.insertBack(TEXT_XML_8859_1);
        values.insertBack(TEXT_XML_UTF_8);
        values.insertBack(TEXT_JSON_8859_1);
        values.insertBack(TEXT_JSON_UTF_8);
    }


    private string _string;
    private MimeType _base;
    private ByteBuffer _buffer;
    // private Charset _charset;
    private string _charsetString;
    private bool _assumedCharset;

    this(string s) {
        _string = s;
        _buffer = BufferUtils.toBuffer(s);
        _base = this;
        // _charset = null;
        _charsetString = null;
        _assumedCharset = false;
    }

    this(string s, MimeType base) {
        _string = s;
        _buffer = BufferUtils.toBuffer(s);
        _base = base;
        ptrdiff_t i = s.indexOf(";charset=");
        // _charset = Charset.forName(s.substring(i + 9));
        if(i == -1) {
            _charsetString = null;
            _assumedCharset = true;
        } else {
            _charsetString = s[i + 9 .. $].toLower();
            _assumedCharset = false;
        }
    }

    this(string s, string charset) {
        _string = s;
        _base = this;
        _buffer = BufferUtils.toBuffer(s);
        // _charset = charset;
        _charsetString = charset.toLower();
        _assumedCharset = true;
    }

    // ByteBuffer asBuffer() {
    //     return _buffer.asReadOnlyBuffer();
    // }

    // Charset getCharset() {
    //     return _charset;
    // }

    string getCharsetString() {
        return _charsetString;
    }

    bool isSame(string s) {
        return _string.equalsIgnoreCase(s);
    }

    string asString() {
        return _string;
    }

    override
    string toString() {
        return _string;
    }

    bool isCharsetAssumed() {
        return _assumedCharset;
    }

    MimeType getBaseType() {
        return _base;
    }
}

