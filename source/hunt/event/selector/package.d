/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module hunt.event.selector;

import hunt.common;
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
