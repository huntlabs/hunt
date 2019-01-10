/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2019  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.net
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
