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

module hunt.io.socket;

public import hunt.io.socket.Common;

version (Posix) {
    public import hunt.io.socket.Posix;
} else version (Windows) {
    public import hunt.io.socket.IOCP;
}
