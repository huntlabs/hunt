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

public import hunt.event.selector.Selector;

version (HAVE_EPOLL) {
    public import hunt.event.selector.Epoll;
} else version (HAVE_KQUEUE) {
    public import hunt.event.selector.Kqueue;

} else version (HAVE_IOCP) {
    public import hunt.event.selector.IOCP;
} else {
    static assert(false, "unsupported platform");
}
