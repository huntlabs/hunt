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
            (cast(ConnectCompletionHandle)_handle).completed(_handleAttachment);
            return true;
        }
        else if (isWriteed()) 
        {   
            if (_attachment is null)
            {
                log(LogLevel.warning , "write buffer is null");
                (cast(WriteCompletionHandle)_handle).failed(_handleAttachment);
                return false;
            }
            long n = _attachment.getCurBuffer().length;
            long len;

            while(n > 0)
            {
                //TODO 写失败
                len = _channel.socket().send(_attachment.getCurBuffer());
                if (len < n) 
                {
                    int err = errno(); 
                    if (len == -1 && errno != EAGAIN) 
                    {
                        log(LogLevel.warning , "write failed");
                        (cast(WriteCompletionHandle)_handle).failed(_handleAttachment);
                        return false;
                    }
                    n -= len;
                    _attachment.offsetLimit(len);
                    break;
                }
                n -= len;
                _attachment.offsetLimit(len);
            }

            (cast(WriteCompletionHandle)_handle).completed(_attachment.getPosition(), _attachment, _handleAttachment);
            return true;
        }
        return false;
    }
    override bool onRead() {
        if (isAccepted())
        {
            AsynchronousSocketChannel client = AsynchronousSocketChannel.open(_channel.getGroup(), _selector);
            client.setOpen(true);
            client.setSocket((cast(AsynchronousServerSocketChannel)_channel).socket().accept());
            (cast(AcceptCompletionHandle)_handle).completed(client, _handleAttachment);
            return true;
        }
        else if (isReaded()) 
        {
            if (_attachment is null)
            {
                log(LogLevel.warning , "read buffer is null");
                writeln("read buffer is null");
                (cast(ReadCompletionHandle)_handle).failed(_handleAttachment);
                return false;
            }
            long len;
            while((len = _channel.socket().receive(_attachment.getLeftBuffer())) > 0)
            {
                _attachment.offsetPos(len);
            }
            int err = errno(); 

            if (len == -1 && EAGAIN != err)
            {
                log(LogLevel.warning , "read failed");
                writeln("read failed");
                (cast(ReadCompletionHandle)_handle).failed(_handleAttachment);
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
                (cast(ReadCompletionHandle)_handle).completed(_attachment.getPosition(), _attachment, _handleAttachment);
                return true;
            }
        }
        return false;
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


    @property ByteBuffer attachment(){return _attachment;}
    @property void attachment(ByteBuffer obj){_attachment = obj;}


    @property void* handle(){return _handle;}
    @property void handle(void* obj){ _handle = obj; }


    @property void* handleAttachment(){return _handleAttachment;}
    @property void handleAttachment(void* obj){ _handleAttachment = obj; }
    



    void interestOps(int ops, bool isNew)
    {
        if (isNew)
        {
            _selector._epoll.addEvent(this,  _channel.getFd(),  ops);
        }
        else 
        {
            _selector._epoll.modEvent(this,  _channel.getFd(),  ops);
        }

    }



private:

    AsynchronousChannelSelector _selector;
    AsynchronousChannelBase _channel;
    ByteBuffer _attachment;
    void* _handle;
    void* _handleAttachment;


}