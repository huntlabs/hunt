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
 
module hunt.event.socket;

public import hunt.event.socket.common;

version (Posix)
{
    public import hunt.event.socket.posix;
}
else version (Windows)
{
    public import hunt.event.socket.iocp;
}

