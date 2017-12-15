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

Address createAddress(Socket socket, ushort port){
    Address addr;
    if(socket.addressFamily == AddressFamily.INET6)
        addr = new Internet6Address(port);
    else 
        addr = new InternetAddress(port);
    return addr;
}