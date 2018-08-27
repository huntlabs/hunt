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
 
module hunt.io.net.core;

import std.socket;

Address createAddress(Socket socket, ushort port)
{
    Address addr;
    if (socket.addressFamily == AddressFamily.INET6)
        addr = new Internet6Address(port);
    else
        addr = new InternetAddress(port);
    return addr;
}
