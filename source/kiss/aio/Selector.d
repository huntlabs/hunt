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

module kiss.aio.Selector;

import kiss.aio.SelectionKey;
import kiss.aio.ChannelBase;
import kiss.aio.ByteBuffer;
import kiss.aio.epoll;

import std.algorithm.mutation;

class Selector
{
    public
    {
        this()
        {
            //TODO 多平台
            _epoll = new Epoll();
        }

        static open()
        {
            if (_instance is null)
            {
                _instance = new Selector();
            }
            return _instance;
        }

        SelectionKey register(ChannelBase ch, int ops, ByteBuffer obj){
            SelectionKey key = new SelectionKey();
            key.selector(this);
            key.channel(ch);
            key.attachment(obj);
            key.interestOps(ops);
            return key;
        }

        int select(int timeout)
        {
            int num = _epoll.poll(timeout);
            
            _keys = null;
            if (num <= 0)
                return 0;
                
            _keys = new SelectionKey[num];

            for(int i = 0; i < num; i++) {
                epoll_event event = _epoll.getEpollEvent(i);
                uint mask = event.events;
                SelectionKey key = cast(SelectionKey)event.data.ptr;
                if(mask & ( EPOLL_EVENTS.EPOLLERR | EPOLL_EVENTS.EPOLLHUP))
                {
                    key.channel.close();
                }
                else if(mask & EPOLL_EVENTS.EPOLLIN){
                    //connect accept read
                    key.readyOps(key.getInterestOps());
                }
                else if(mask & EPOLL_EVENTS.EPOLLOUT){
                    key.readyOps(key.getInterestOps());
                }
                _keys[i] = key;
            }
            return num;
        }

        @property SelectionKey[] selectorKeys(){
            return _keys;
        }
    }

    public:
        Epoll _epoll;

    private
    {
        static Selector _instance;
        SelectionKey[] _keys;
    }
}
