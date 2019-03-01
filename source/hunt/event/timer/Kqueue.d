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

module hunt.event.timer.Kqueue;

// dfmt off
version (HAVE_KQUEUE) : 
// dfmt on


import hunt.Exceptions;
import hunt.Functions;
import hunt.io.socket.Common;
import hunt.event.timer.Common;
import hunt.io.socket;

import core.stdc.errno;
import core.sys.posix.sys.types; // for ssize_t, size_t
import core.sys.posix.netinet.tcp;
import core.sys.posix.netinet.in_;
import core.sys.posix.time;
import core.sys.posix.unistd;

import std.exception;
import std.socket;

/**
*/
class AbstractTimer : TimerChannelBase {
    this(Selector loop) {
        super(loop);
        setFlag(ChannelFlag.Read, true);
        _sock = new Socket(AddressFamily.UNIX, SocketType.STREAM);
        this.handle = _sock.handle;
        _readBuffer = new UintObject();
    }

    ~this() {
        close();
    }

    bool readTimer(scope SimpleActionHandler read) {
        this.clearError();
        this._readBuffer.data = 1;
        if (read)
            read(this._readBuffer);
        return false;
    }

    UintObject _readBuffer;
    Socket _sock;
}
