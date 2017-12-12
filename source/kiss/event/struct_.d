module kiss.event.struct_;

import std.socket;
import std.exception;

final class UdpDataObject
{
    Address addr;
    ubyte[] data;
}


final class BaseTypeObject(T)
{
    T data;
}


class LoopException : Exception
{
    mixin basicExceptionCtors;
}

