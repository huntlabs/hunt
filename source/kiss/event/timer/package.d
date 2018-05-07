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
 
module kiss.event.timer;

public import kiss.event.timer.common;

version (linux)
{
    public import kiss.event.timer.epoll;
}
else version (Kqueue)
{
    public import kiss.event.timer.kqueue;
}
else version (Windows)
{
    public import kiss.event.timer.iocp;
}
