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

module hunt.logging;

version(HUNT_DEBUG) {
    public import hunt.logging.ConsoleLogger;
} else {
    public import hunt.logging.Logger;
}

public import hunt.logging.Helper;
