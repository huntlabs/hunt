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

module kiss.aio.AsynchronousSelectionKey;

import kiss.aio.AsynchronousChannelSelector;
import kiss.aio.AsynchronousChannelBase;
import kiss.aio.AsynchronousSocketChannel;
import kiss.aio.AsynchronousServerSocketChannel;
import kiss.aio.ByteBuffer;
import kiss.aio.CompletionHandle;
import kiss.aio.Event;
import std.experimental.logger;
import core.stdc.errno;

import std.stdio;
import core.thread;



class AsynchronousSelectionKey : Event{

public:

    bool isAccepted() {
    	return (_channel.intrestOps() & AIOEventType.OP_ACCEPTED) != 0;
    }

    bool isConnected() {
        return (_channel.intrestOps() & AIOEventType.OP_CONNECTED) != 0;
    }
    bool isReaded() {
		return (_channel.intrestOps() & AIOEventType.OP_READED) != 0;
    }

    bool isWriteed() {
        return (_channel.intrestOps() & AIOEventType.OP_WRITEED) != 0;
    }

    override bool onWrite() {

        if (isConnected())
        {
            if (errno() == EBADF)
                onFailed(AIOEventType.OP_CONNECTED ,_handleAttachment);
            else 
                onCompleted(AIOEventType.OP_CONNECTED ,_handleAttachment);
            _channel.unRegisterOp(AIOEventType.OP_CONNECTED);
            return true;
        }
        else if (isWriteed()) 
        {   
            if (_writeBuffer is null)
            {
                log(LogLevel.warning , "write buffer is null");
                onFailed(AIOEventType.OP_WRITEED ,_handleAttachment);
                return false;
            }
            long n = _writeBuffer.getCurBuffer().length;
            long len;

            while(n > 0)
            {
                //TODO write failed
                len = _channel.socket().send(_writeBuffer.getCurBuffer());
                if (len < n) 
                {
                    int err = errno(); 
                    if (len == -1 && errno != EAGAIN) 
                    {
                        log(LogLevel.warning , "write failed");
                        onFailed(AIOEventType.OP_WRITEED ,_handleAttachment);
                        return false;
                    }
                    n -= len;
                    _writeBuffer.offsetLimit(len);
                    break;
                }
                n -= len;
                _writeBuffer.offsetLimit(len);
            }
            onCompleted(AIOEventType.OP_WRITEED , cast(void*)_handleAttachment, cast(void*)_writeBuffer.getPosition(), cast(void*)_writeBuffer);
            return true;
        }
        return true;
    }
    override bool onRead() {
        if (isAccepted())
        {
            AsynchronousSocketChannel client = AsynchronousSocketChannel.open(_channel.getGroup(), _selector);
            client.setOpen(true);
            client.setSocket((cast(AsynchronousServerSocketChannel)_channel).socket().accept());

            onCompleted(AIOEventType.OP_ACCEPTED , _handleAttachment ,cast(void*)client);
            return true;
        }
        else if (isReaded()) 
        {
            if (_readBuffer is null)
            {
                log(LogLevel.warning , "read buffer is null");
                onFailed(AIOEventType.OP_READED ,_handleAttachment);
                return false;
            }
            long len;
            while((len = _channel.socket().receive(_readBuffer.getLeftBuffer())) > 0)
            {
                _readBuffer.offsetPos(len);
            }
            int err = errno(); 

            if (len == -1 && EAGAIN != err)
            {
                log(LogLevel.warning , "read failed");
                onFailed(AIOEventType.OP_READED ,_handleAttachment);
                return false;
            }
            // else if( len == 0)
            // {
            //     writeln("connection was closed!!!");
            //     (cast(ReadCompletionHandle)_handle).failed(_handleAttachment);
            //     return false;
            // }
            else 
            {
                onCompleted(AIOEventType.OP_READED, cast(void*)_handleAttachment, cast(void*)_readBuffer.getPosition(), cast(void*)_readBuffer);
                return true;
            }
        }
        return true;
    }

    override bool onClose() {
        return _channel.onClose();
    }
    
	override bool isReadyClose() {
        return _channel.isReadyClose();
    }


    @property AsynchronousChannelSelector selector(){return _selector;}
    @property void selector(AsynchronousChannelSelector sel){_selector = sel;}

    @property AsynchronousChannelBase channel(){return _channel;}
    @property void channel(AsynchronousChannelBase ch){_channel = ch;}

    @property void* handle(){return _handle;}
    @property void handle(void* obj){ _handle = obj; }


    @property void* handleAttachment(){return _handleAttachment;}
    @property void handleAttachment(void* obj){ _handleAttachment = obj; }
    

public:
    ByteBuffer _readBuffer;
    ByteBuffer _writeBuffer;


private:
    void onCompleted(AIOEventType op, void* attachment, void* param1 = null, void* param2 = null)
    {
        (cast(AsynchronousChannelBase)_handle).completed(op, attachment, param1, param2);
    }
    void onFailed(AIOEventType op, void* attachment)
    {
        (cast(AsynchronousChannelBase)_handle).failed(op, attachment);
    }


private:
    AsynchronousChannelSelector _selector;
    AsynchronousChannelBase _channel;


    void* _handle;
    void* _handleAttachment;



}






