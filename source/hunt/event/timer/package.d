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

module hunt.event.timer;

public import hunt.event.timer.Common;

version (HAVE_EPOLL) {
    public import hunt.event.timer.Epoll;
} else version (HAVE_KQUEUE) {
    public import hunt.event.timer.Kqueue;
} else version (HAVE_IOCP) {
    public import hunt.event.timer.IOCP;
}
