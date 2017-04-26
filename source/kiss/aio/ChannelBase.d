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

module kiss.aio.ChannelBase;

import kiss.aio.SelectionKey;
import kiss.aio.Selector;
import core.sync.mutex;
import std.socket;
import kiss.aio.ByteBuffer;
import std.experimental.logger.core;
import core.stdc.errno;
import std.stdio;

class ChannelBase {

public:

    this(){
        regLock = new Mutex();
        writeLock = new Mutex();
        readLock = new Mutex();
    }
  
    abstract int validOps();
    
    

    bool isBlocking(){
        synchronized (regLock) {
            return blocking;
        }
    }

    bool isOpen(){
        return _open;
    }
    void setOpen(bool b)
    {
        _open = b;
    }


    bool haveValidKeys()
    {
        if (keyCount == 0 || keys is null)
            return false;
        for(int i = 0; i < keys.length; i ++) {
            if (!(keys[i] is null))
                return true;
        }
        return false;
    }

    void configureBlocking(bool block)
    {
        // if (!isOpen())
        //     return;
        if (blocking == block)
            return;
        if (block && haveValidKeys())
            return;

        blocking = block;
        if (!(_socket is null))
        {
            _socket.blocking(block);
        }
        return;
    }


    SelectionKey register(Selector sel,int ops, ByteBuffer obj = null) {
        synchronized(regLock)
        {
            SelectionKey k;
            if (!isOpen())
            {
                log(LogLevel.info , "Channel was closed!!!");
                return null;
            }
            if ((ops & ~validOps()) != 0)
            {
                log(LogLevel.info , "Channel unsupport ops!!!");
                return null;
            }
            if (blocking)
            {
                log(LogLevel.info , "Channel is Block!!!");
                return null;
            }
            k = findKey(sel);
            if (!(k is null))
            {
                k.interestOps(ops);
                k.attachment(obj);
            }
            else 
            {
                if (!isOpen())
                {
                    log(LogLevel.info , "Channel is closed!!!");
                    return null;
                }
                k = sel.register(this, ops, obj);
                addKey(k);
            }

            return k;
        }
    }

    void setInterestOps(int ops)
    {
        _interestOps = ops;
    }

    int getInterestOps()
    {
        return _interestOps;
    }

    void close()
    {
        foreach(value; keys) {
            if (!(value is null))
            {
                value._selector._epoll.delEvent(value,getFd(),0);
                break;
            }
        }
        keys.destroy();

        _socket.close();
        setOpen(false);
    }

    int getFd()
    {
        return cast(int)(_socket.handle);
    }

    long write(ByteBuffer buf)
    {
        synchronized (writeLock) {
            if (!isOpen())
            {
                buf.release();
                return 0;
            }
			long len = _socket.send(buf.getCurBuffer());
            if (len >= 0)
            {
                buf.offsetPos(len);
                return len;
            }
            else 
            {
                 if(net_error())
                 {
                    log(LogLevel.error , "write net error");
                 }
                 buf.release();
                 return -1;
            }
        }
    }

    long read(ByteBuffer buf) {
        synchronized(readLock) {
            if (!isOpen())
            {
                buf.release();
                return 0;
            }
            long len = _socket.receive(buf.getLeftBuffer());

            if (len == 0)
            {
                buf.release();
                log(LogLevel.info , "peer close socket");
                return 0;
            }
            else if(len == -1 && net_error())
            {
                buf.release();

                log(LogLevel.error , "error");
                return 0;
            }
            buf.offsetPos(len);
            return len;
        }
    }

    //TODO
    void setOption()
    {
        _socket.setOption(SocketOptionLevel.SOCKET , SocketOption.REUSEADDR , 1);
    }



private:
    SelectionKey findKey(Selector sel)
    {
        synchronized(regLock){
            if(keys is null)
                return null;
            foreach(value; keys) {
                if (!(value is null) && value.selector() == sel)
                {
                    return value;
                }
            }
            return null;
        }
    }

    void addKey(SelectionKey k) 
    {   
        int i = 0;
        if (!(keys is null) && keyCount < keys.length){
            foreach(value; keys) {
                if (value is null)
                    break;
            }
        }else if(keys is null){
            keys = new SelectionKey[3];
        }else {
            ulong n = (keys.length) * 2;
            SelectionKey[] ks = new SelectionKey[n];
            foreach(value; keys) {
                ks[i] = value;
            }
            keys = ks;
            i = keyCount;
        }
        keys[i] = k;
        keyCount++;
    }

    static package bool net_error()
	{
		int err = errno();
		if(err == 0 || err == EAGAIN || err == EWOULDBLOCK || err == EINTR || err == EINPROGRESS)
			return false;	
		return true;
	}
    

public:
    Socket _socket;
protected:
    Mutex regLock;
    Mutex writeLock;
    Mutex readLock;
    bool blocking = true;
    int keyCount = 0;
    SelectionKey[] keys;


private:
    int _interestOps = -1;
    bool _open = false;

}