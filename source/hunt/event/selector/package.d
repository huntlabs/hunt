/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.net
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module hunt.event.selector;

import hunt.lang.common;
import hunt.event.core;
import std.conv;


version (linux)
{
    public import hunt.event.selector.epoll;

    // alias HuntSelector = AbstractSelector;

}
else version (Kqueue)
{

    // alias HuntSelector = KqueueLoop;

    public import hunt.event.selector.kqueue;

}
else version (Windows)
{
    public import hunt.event.selector.iocp;

    // alias HuntSelector = IocpSelector;

}
else
{
    static assert(false, "unsupported platform");
}
