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

module hunt.logging.helper;

version(HUNT_DEBUG) {
    import hunt.logging.ConsoleLogger;
} else {
    import hunt.logging.Logger;
}


import core.runtime;
import core.stdc.stdlib;
import std.exception;

void catchAndLogException(E)(lazy E runer) @trusted nothrow
{
    try
    {
        runer();
    }
    catch (Exception e)
    {
        collectException(warning(e.toString));
    }
    catch (Error e)
    {
        collectException(() { error(e.toString); rt_term(); }());
        exit(-1);
    }
}