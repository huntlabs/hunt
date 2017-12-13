module kiss.bytes;

import core.stdc.string;
import std.bitmanip;
import kiss.traits;

ptrdiff_t findCharByte(T)(in T[] data, in T ch) if (isCharByte!(T)) {
    if (data.length == 0)
        return -1;
    ptrdiff_t index = -1;
    auto ptr = memchr(data.ptr, ch, data.length);
    if (ptr !is null) {
        index = cast(ptrdiff_t)((cast(T*) ptr) - data.ptr);
    }

    return index;
}

ptrdiff_t findCharBytes(T)(in T[] data, in T[] chs) if (isCharByte!(T)) {
    if (data.length < chs.length || data.length == 0 || chs.length == 0)
        return -1;
    ptrdiff_t index = -1;
    size_t rsize = 0;
    while (rsize < data.length) {
        auto tdata = data[rsize .. $];
        auto ptr = memchr(tdata.ptr, chs[0], tdata.length);
        if (ptr is null)
            break;

        size_t fistindex = (cast(T*) ptr) - tdata.ptr;
        if (tdata.length - fistindex < chs.length)
            break;

        size_t i = 1;
        size_t j = fistindex + 1;
        while (i < chs.length && j < tdata.length) {
            if (chs[i] != tdata[j]) {
                rsize += fistindex + 1;
                goto next;
            }
            ++i;
            ++j;
        }
        index = cast(ptrdiff_t)(rsize + fistindex);
        break;
    next:
        continue;
    }
    return index;
}

template endianToNative(bool litte, T) {
    static if (litte)
        alias endianToNative = littleEndianToNative!(T, T.sizeof);
    else
        alias endianToNative = bigEndianToNative!(T, T.sizeof);
}

template nativeToEndian(bool litte, T) {
    static if (litte)
        alias nativeToEndian = nativeToLittleEndian!(T);
    else
        alias nativeToEndian = nativeToBigEndian!(T);

}

unittest {
    string hello = "hell worlf\r\nnext";
    assert(findCharByte(hello, 'l') == 2);
    assert(findCharBytes(hello, "worlf") == 5);
}
