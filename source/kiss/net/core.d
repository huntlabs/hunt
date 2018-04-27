module kiss.net.core;

import std.socket;

Address createAddress(Socket socket, ushort port)
{
    Address addr;
    if (socket.addressFamily == AddressFamily.INET6)
        addr = new Internet6Address(port);
    else
        addr = new InternetAddress(port);
    return addr;
}


/**
*/

deprecated("to be removed") 
mixin template TransportSocketOption()
{
    import std.functional;
    import std.datetime;
    import core.stdc.stdint;
    import std.socket;

    version (Windows) import SOCKETOPTIONS = core.sys.windows.winsock2;

    version (Posix) import SOCKETOPTIONS = core.sys.posix.sys.socket;

    /// Get a socket option.
    /// Returns: The number of bytes written to $(D result).
    //returns the length, in bytes, of the actual result - very different from getsockopt()
    pragma(inline) final int getOption(SocketOptionLevel level, SocketOption option, void[] result) @trusted
    {

        return _watcher.socket.getOption(level, option, result);
    }

    /// Common case of getting integer and boolean options.
    pragma(inline) final int getOption(SocketOptionLevel level,
            SocketOption option, ref int32_t result) @trusted
    {
        return _watcher.socket.getOption(level, option, result);
    }

    /// Get the linger option.
    pragma(inline) final int getOption(SocketOptionLevel level, SocketOption option,
            ref Linger result) @trusted
    {
        return _watcher.socket.getOption(level, option, result);
    }

    /// Get a timeout (duration) option.
    pragma(inline) final void getOption(SocketOptionLevel level,
            SocketOption option, ref Duration result) @trusted
    {
        _watcher.socket.getOption(level, option, result);
    }

    /// Set a socket option.
    pragma(inline) final void setOption(SocketOptionLevel level, SocketOption option, void[] value) @trusted
    {
        return _watcher.socket.setOption(forward!(level, option, value));
    }

    /// Common case for setting integer and boolean options.
    pragma(inline) final void setOption(SocketOptionLevel level, SocketOption option, int32_t value) @trusted
    {
        return _watcher.socket.setOption(forward!(level, option, value));
    }

    /// Set the linger option.
    pragma(inline) final void setOption(SocketOptionLevel level, SocketOption option, Linger value) @trusted
    {
        return _watcher.socket.setOption(forward!(level, option, value));
    }

    pragma(inline) final void setOption(SocketOptionLevel level, SocketOption option, Duration value) @trusted
    {
        return _watcher.socket.setOption(forward!(level, option, value));
    }

    // you should be yDel the Address
    final @property @trusted Address remoteAddress()
    {
        // return _watcher.socket.remoteAddress();
        return _remoteAddress;
    }
    protected Address _remoteAddress;

    final @property @trusted Socket socket()
    {
        return _watcher.socket;
    }

    // you should be yDel the Address
    final @property @trusted Address localAddress()
    {
        return _watcher.socket.localAddress();
    }
}
