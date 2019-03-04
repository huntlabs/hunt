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

module hunt.io.channel;

public import hunt.io.channel.AbstractChannel;
public import hunt.io.channel.AbstractSocketChannel;
public import hunt.io.channel.Common;

version (Posix) {
    public import hunt.io.channel.posix;
} else version (Windows) {
    public import hunt.io.channel.iocp;
}
