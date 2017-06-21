/*
 * KISS - A refined core library for dlang
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module kiss.aio.AsynchronousServerSocketChannel;

import kiss.aio.AsynchronousSocketChannel;
import kiss.aio.CompletionHandle;
import kiss.aio.AsynchronousChannelBase;
import kiss.aio.ByteBuffer;
import kiss.aio.AsynchronousChannelThreadGroup;
import kiss.aio.Event;
import kiss.util.Common;
import std.conv;
import std.socket;


class AsynchronousServerSocketChannel : AsynchronousChannelBase{

public:
    this(AsynchronousChannelThreadGroup group)
    {
        super(group, group.getWorkSelector());
    }
    

    static open(AsynchronousChannelThreadGroup group)
    {
        return new AsynchronousServerSocketChannel(group);
    }

    
    void accept(void* attachment, AcceptCompletionHandle handler)
    {
        register(AIOEventType.OP_ACCEPTED, cast(void*)handler, attachment);
    }

    void bind(string ip, ushort port, int backlog = 1024)
    {
        AddressInfo[] arr = getAddressInfo(ip , to!string(port) , AddressInfoFlags.PASSIVE);
        _socket = new Socket(arr[0].family , arr[0].type , arr[0].protocol);
        
        _socket.setOption(SocketOptionLevel.SOCKET , SocketOption.REUSEADDR , 1);
        static if (IOMode == IO_MODE.epoll)
        {
            //SO_REUSEPORT
            _socket.setOption(SocketOptionLevel.SOCKET, cast(SocketOption) 15, 1);
        }

        _socket.bind(arr[0].address);
        _socket.blocking(false);
        _socket.listen(backlog);
        setOpen(true);
    }

    override int validOps(){
        return AIOEventType.OP_ACCEPTED;
    }




}