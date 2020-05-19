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

module hunt.util.StringBuffer;

import hunt.util.Common;

import std.array;
import std.conv;

/**
 * 
 */
class StringBuffer : Appendable {
    Appender!string _buffer;

    this(size_t capacity = 16) {

    }

    void setLength(int len) {
        if (len == 0) {
            _buffer = Appender!(string).init;
        } else {
            string tmp = _buffer.data[0 .. len];

            _buffer = Appender!(string).init;
            _buffer.put(tmp);
        }
    }

    void clear() {
        _buffer = Appender!(string).init;
    }

    int length() {
        return cast(int) _buffer.data.length;
    }

    Appendable append(const(char)[] csq) {
        _buffer.put(csq);
        return this;
    }

    Appendable append(const(char)[] csq, int start, int end) {
        _buffer.put(csq[start .. end]);
        return this;
    }

    Appendable append(char c) {
        _buffer.put(c);
        return this;
    }

    Appendable append(int c) {
        string s = to!string(c);
        _buffer.put(s);
        return this;
    }

    Appendable append(float c) {
        string s = to!string(c);
        _buffer.put(s);
        return this;
    }

    override string toString() {
        return _buffer.data;
    }

}
