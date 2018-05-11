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
 
module kiss.event.socket;

public import kiss.event.socket.common;

version (Posix)
{
    public import kiss.event.socket.posix;
}
else version (Windows)
{
    public import kiss.event.socket.iocp;
}

