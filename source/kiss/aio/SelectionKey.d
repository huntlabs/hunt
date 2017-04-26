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

module kiss.aio.SelectionKey;

import kiss.aio.Selector;
import kiss.aio.ChannelBase;
import kiss.aio.ByteBuffer;
import std.stdio;


class SelectionKey {

    //Operation-set bit for read operations.
    public static const int OP_READ = 1 << 0;
    //Operation-set bit for write operations.
    public static const int OP_WRITE = 1 << 2;
    //Operation-set bit for socket-connect operations.
    public static const int OP_CONNECT = 1 << 3;
    //Operation-set bit for socket-accept operations.
    public static const int OP_ACCEPT = 1 << 4;


public:

    @property int readyOps(){
        return _curOps;
    }
    @property void readyOps(int ops){
        _curOps = ops;
    }

    bool isAcceptable(){
		return (readyOps & OP_ACCEPT) != 0;
    }

    bool isConnectable(){
        return (readyOps & OP_CONNECT) != 0;
    }
    bool isReadable(){
		return (readyOps & OP_READ) != 0;
    }

    bool isWritable(){
        return (readyOps & OP_WRITE) != 0;
    }

    bool isValid(){
        return true;
    } 


    @property Selector selector(){return _selector;}
    @property void selector(Selector sel){_selector = sel;}

    @property ChannelBase channel(){return _channel;}
    @property void channel(ChannelBase ch){_channel = ch;}


    @property ByteBuffer attachment(){return _attachment;}
    @property void attachment(ByteBuffer obj){_attachment = obj;}


    SelectionKey interestOps(int ops)
    {
        if (_channel.getInterestOps() == -1)
        {
            _selector._epoll.addEvent(this,  _channel.getFd(),  ops);
        }
        else 
        {
            _selector._epoll.modEvent(this,  _channel.getFd(),  ops);
        }
        _channel.setInterestOps(ops);
        _ops = ops;
        
        return this;
    }

    int getInterestOps()
    {
        return _ops;
    }

    Selector _selector;
    
private:
    ChannelBase _channel;
    ByteBuffer _attachment;
    int _ops;
    int _curOps = -1;
}