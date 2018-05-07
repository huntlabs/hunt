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

import kiss.event.core;

version (Posix)
{
    public import kiss.event.socket.posix;
    // alias KissAcceptor = PosixAcceptor;
    // alias KissStream = PosixStream;
    // alias KissDatagram = PosixDatagram;
}
// else version (Kqueue)
// {

// }
else version (Windows)
{
    public import kiss.event.socket.iocp;
    // alias KissAcceptor = IocpAcceptor;
    // alias KissStream = IocpStream;
    // alias KissDatagram = IocpDatagram;

    // deprecated("Using KissAcceptor instead!")
    // alias IOCPAcceptWatcher = IocpAcceptor;
}

