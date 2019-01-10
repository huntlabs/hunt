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
 
module hunt.event.timer;

public import hunt.event.timer.common;

version (linux)
{
    public import hunt.event.timer.epoll;
}
else version (Kqueue)
{
    public import hunt.event.timer.kqueue;
}
else version (Windows)
{
    public import hunt.event.timer.iocp;
}
