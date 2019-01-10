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

import hunt.Exceptions;
import hunt.io.socket.Common;
import std.conv;

version (linux) {
    public import hunt.event.selector.Epoll;
} else version (Kqueue) {
    public import hunt.event.selector.Kqueue;

} else version (Windows) {
    public import hunt.event.selector.IOCP;
} else {
    static assert(false, "unsupported platform");
}
