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
 
module hunt.io.event.selector;

import hunt.common;
import hunt.io.event.core;
import std.conv;


version (linux)
{
    public import hunt.io.event.selector.epoll;

    // alias KissSelector = AbstractSelector;

}
else version (Kqueue)
{

    // alias KissSelector = KqueueLoop;

    public import hunt.io.event.selector.kqueue;

}
else version (Windows)
{
    public import hunt.io.event.selector.iocp;

    // alias KissSelector = IocpSelector;

}
else
{
    static assert(false, "unsupported platform");
}
