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

version (linux) {
    public import hunt.event.timer.Epoll;
} else version (Kqueue) {
    public import hunt.event.timer.Kqueue;
} else version (Windows) {
    public import hunt.event.timer.IOCP;
}
