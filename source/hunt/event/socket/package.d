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

