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

module hunt.util.StringBuilder;

import hunt.util.Appendable;

import std.ascii;
import std.algorithm;
import std.array;
import std.exception;
import std.conv;
import std.string;
import std.uni;

/**
 * 
 */
class StringBuilder : Appendable {
    Appender!(byte[]) _buffer;

    this(size_t capacity = 16) {
        _buffer.reserve(capacity);
    }

    this(string data, size_t capacity = 16) {
        _buffer.reserve(capacity);
        this.append(data);
    }

    // void append(in char[] s)
    // {
    //     _buffer.put(cast(string) s);
    // }

    void reset() {
        _buffer.clear();
    }

    StringBuilder setCharAt(int index, char c) {
        _buffer.data[index] = c;
        return this;
    }

    StringBuilder append(char s) {
        _buffer.put(s);
        return this;
    }

    StringBuilder append(bool s) {
        append(s.to!string());
        return this;
    }

    StringBuilder append(int i) {
        _buffer.put(cast(byte[])(to!(string)(i)));
        return this;
    }

    StringBuilder append(float f) {
        _buffer.put(cast(byte[])(to!(string)(f)));
        return this;
    }

    StringBuilder append(const(char)[] s) {
        _buffer.put(cast(byte[]) s);
        return this;
    }

    StringBuilder append(const(char)[] s, int start, int end) {
        _buffer.put(cast(byte[]) s[start .. end]);
        return this;
    }

    // StringBuilder append(byte[] s, int start, int end)
    // {
    //     _buffer.put(s[start..end]);
    //     return this;
    // }

    /// Warning: It's different from the previous one.
    StringBuilder append(byte[] str, int offset, int len) {
        _buffer.put(str[offset .. offset + len]);
        return this;
    }

    StringBuilder append(Object obj) {
        _buffer.put(cast(byte[])(obj.toString));
        return this;
    }

    int length() {
        return cast(int) _buffer.data.length;
    }

    void setLength(int newLength) {
        _buffer.shrinkTo(newLength);
        // if (newLength < 0)
        //     throw new StringIndexOutOfBoundsException(to!string(newLength));
        // ensureCapacityInternal(newLength);

        // if (count < newLength) {
        //     Arrays.fill(value, count, newLength, '\0');
        // }

        // count = newLength;
    }

    private void ensureCapacityInternal(size_t minimumCapacity) {
        // overflow-conscious code
        // if (minimumCapacity > value.length) {
        //     value = Arrays.copyOf(value,
        //             newCapacity(minimumCapacity));
        // }
    }

    int lastIndexOf(string s) {
        string source = cast(string) _buffer.data;
        return cast(int) source.lastIndexOf(s);
    }

    char charAt(int idx) {
        if (length() > idx)
            return _buffer.data[idx];
        else
            return ' ';
    }

    StringBuilder deleteCharAt(int index) {
        if (index < length()) {
            auto data = _buffer.data.idup;
            for (int i = index + 1; i < data.length; i++) {
                _buffer.data[i - 1] = data[i];
            }
            setLength(cast(int)(data.length - 1));
        }
        return this;
    }

    StringBuilder insert(int index, char c) {
        if (index <= length()) {
            auto data = _buffer.data.idup;
            for (int i = index; i < data.length; i++) {
                _buffer.data[i + 1] = data[i];
            }
            _buffer.data[index] = c;
            setLength(cast(int)(data.length + 1));
        }
        return this;
    }

    StringBuilder insert(int index, long data) {
        auto bytes = cast(byte[])(to!string(data));
        auto start = index;
        foreach (b; bytes) {
            insert(start, cast(char) b);
            start++;
        }
        return this;
    }

    StringBuilder replace(int start, int end, string str) {
        if (start <= end && start < length() && end < length()) {
            if (str.length >= end)
                _buffer.data[start .. end] = cast(byte[])(str[start .. end]);
        }
        return this;
    }

    void clear() {
        _buffer = Appender!(byte[]).init;
    }

    override string toString() {
        string s = cast(string) _buffer.data.idup;
        if (s is null)
            return "";
        else
            return s;
    }
}
