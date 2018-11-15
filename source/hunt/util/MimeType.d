module hunt.util.MimeType;

import hunt.util.AcceptMimeType;

import hunt.container;
import hunt.logging;

import hunt.lang.Charset;
import hunt.lang.exception;
import hunt.string;
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
    __gshared MimeType FORM_ENCODED ;
    __gshared MimeType MESSAGE_HTTP ;
    __gshared MimeType MULTIPART_BYTERANGES ;

    __gshared MimeType TEXT_HTML ;
    __gshared MimeType TEXT_PLAIN ;
    __gshared MimeType TEXT_XML ;
    __gshared MimeType TEXT_JSON ;
    __gshared MimeType APPLICATION_JSON ;
    __gshared MimeType APPLICATION_XML ;

    __gshared MimeType TEXT_HTML_8859_1 ;
    __gshared MimeType TEXT_HTML_UTF_8 ;

    __gshared MimeType TEXT_PLAIN_8859_1 ;
    __gshared MimeType TEXT_PLAIN_UTF_8 ;

    __gshared MimeType TEXT_XML_8859_1 ;
    __gshared MimeType TEXT_XML_UTF_8 ;

    __gshared MimeType TEXT_JSON_8859_1 ;
    __gshared MimeType TEXT_JSON_UTF_8 ;

    __gshared MimeType APPLICATION_JSON_8859_1 ;
    __gshared MimeType APPLICATION_JSON_UTF_8 ;

    __gshared Array!MimeType values;

    shared static this() {
        MESSAGE_HTTP = new MimeType("message/http");
        MULTIPART_BYTERANGES = new MimeType("multipart/byteranges");

        TEXT_HTML = new MimeType("text/html");
        TEXT_PLAIN = new MimeType("text/plain");
        TEXT_XML = new MimeType("text/xml");
        TEXT_JSON = new MimeType("text/json", StandardCharsets.UTF_8);
        APPLICATION_JSON = new MimeType("application/json", StandardCharsets.UTF_8);
        APPLICATION_XML = new MimeType("application/xml", StandardCharsets.UTF_8);

        TEXT_HTML_8859_1 = new MimeType("text/html;charset=iso-8859-1", TEXT_HTML);
        TEXT_HTML_UTF_8 = new MimeType("text/html;charset=utf-8", TEXT_HTML);

        TEXT_PLAIN_8859_1 = new MimeType("text/plain;charset=iso-8859-1", TEXT_PLAIN);
        TEXT_PLAIN_UTF_8 = new MimeType("text/plain;charset=utf-8", TEXT_PLAIN);

        TEXT_XML_8859_1 = new MimeType("text/xml;charset=iso-8859-1", TEXT_XML);
        TEXT_XML_UTF_8 = new MimeType("text/xml;charset=utf-8", TEXT_XML);

        TEXT_JSON_8859_1 = new MimeType("text/json;charset=iso-8859-1", TEXT_JSON);
        TEXT_JSON_UTF_8 = new MimeType("text/json;charset=utf-8", TEXT_JSON);

        APPLICATION_JSON_8859_1 = new MimeType("application/json;charset=iso-8859-1", APPLICATION_JSON);
        APPLICATION_JSON_UTF_8 = new MimeType("application/json;charset=utf-8", APPLICATION_JSON);

        values.insertBack(MESSAGE_HTTP);
        values.insertBack(MULTIPART_BYTERANGES);
        values.insertBack(TEXT_HTML);
        values.insertBack(TEXT_PLAIN);
        values.insertBack(TEXT_XML);
        values.insertBack(TEXT_JSON);
        values.insertBack(APPLICATION_JSON);
        values.insertBack(APPLICATION_XML);
        values.insertBack(TEXT_HTML_8859_1);
        values.insertBack(TEXT_HTML_UTF_8);
        values.insertBack(TEXT_PLAIN_8859_1);
        values.insertBack(TEXT_PLAIN_UTF_8);
        values.insertBack(TEXT_XML_8859_1);
        values.insertBack(TEXT_XML_UTF_8);
        values.insertBack(TEXT_JSON_8859_1);
        values.insertBack(TEXT_JSON_UTF_8);
        values.insertBack(APPLICATION_JSON_8859_1);
        values.insertBack(APPLICATION_JSON_UTF_8);
    }


    private string _string;
    private MimeType _base;
    private ByteBuffer _buffer;
    // private Charset _charset;
    private string _charsetString;
    private bool _assumedCharset;
    // private HttpField _field;

    this(string s) {
        _string = s;
        _buffer = BufferUtils.toBuffer(s);
        _base = this;
        // _charset = null;
        _charsetString = null;
        _assumedCharset = false;
        // _field = new PreEncodedHttpField(HttpHeader.CONTENT_TYPE, _string);
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
        // _field = new PreEncodedHttpField(HttpHeader.CONTENT_TYPE, _string);
    }

    this(string s, string charset) {
        _string = s;
        _base = this;
        _buffer = BufferUtils.toBuffer(s);
        // _charset = charset;
        _charsetString = charset.toLower(); // _charset == null ? null : _charset.toString().toLower();
        _assumedCharset = true;
        // _field = new PreEncodedHttpField(HttpHeader.CONTENT_TYPE, _string);
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

    // HttpField getContentTypeField() {
    //     return _field;
    // }

    MimeType getBaseType() {
        return _base;
    }
}

