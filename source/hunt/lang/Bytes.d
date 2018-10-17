module hunt.lang.Bytes;

import std.conv;

class Bytes{

    private byte[] _bytes;

    this(byte[] bs)
    {
        _bytes = bs.dup;
    }

}