module hunt.math.Bytes;

import std.conv;

class Bytes{

    private byte[] _bytes;

    this(byte[] bs)
    {
        _bytes = bs.dup;
    }

}