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

module kiss.aio.AsynchronousSocketChannel;



import kiss.aio.AsynchronousChannelSelector;
import kiss.aio.CompletionHandle;
import kiss.aio.AsynchronousChannelBase;
import kiss.aio.AsynchronousChannelThreadGroup;
import kiss.aio.Event;

import std.conv;
import std.socket;

class AsynchronousSocketChannel : AsynchronousChannelBase{



public:

    this(AsynchronousChannelSelector sel)
    {
        super(sel);
    }

    static open( AsynchronousChannelSelector sel)
    {
        return new AsynchronousSocketChannel(sel);
    }

    
    
    
    void connect(string ip, ushort port, ConnectCompletionHandle handle, void* attachment)
    {
        string strPort = to!string(port);
        AddressInfo[] arr = getAddressInfo(ip , strPort , AddressInfoFlags.CANONNAME);
        _socket = new Socket(arr[0].family , SocketType.STREAM , ProtocolType.TCP);
        _socket.blocking(false);
		_socket.connect(arr[0].address);
        setOpen(true);
        register(AIOEventType.OP_CONNECTED, cast(void*)handle, attachment, null);
    }


    override int validOps(){
        return  (AIOEventType.OP_READED | AIOEventType.OP_WRITEED | AIOEventType.OP_CONNECTED);
    }


}