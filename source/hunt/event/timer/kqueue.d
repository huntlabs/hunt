/*
 * Kiss - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module hunt.event.timer.kqueue;

import hunt.common;

// dfmt off
version (Kqueue) : 
// dfmt on

import hunt.event.core;
import hunt.event.timer.common;
import hunt.event.socket;

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
class AbstractTimer : TimerChannelBase
{
    this(Selector loop)
    {
        super(loop);
        setFlag(WatchFlag.Read, true);
        _sock = new Socket(AddressFamily.UNIX, SocketType.STREAM);
        this.handle = _sock.handle;
        _readBuffer = new UintObject();
    }

    ~this()
    {
        close();
    }


    bool readTimer(scope ReadCallBack read)
    {
        this.clearError();
        this._readBuffer.data = 1;
        if (read)
            read(this._readBuffer);
        return false;
    }

    UintObject _readBuffer;
    Socket _sock;
}
