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

module kiss.exception;

import std.exception;
import std.experimental.logger;

import core.stdc.stdlib;
import core.runtime;

void catchAndLogException(E)(lazy E runer) @trusted nothrow
{
    try
    {
        runer();
    }
    catch (Exception e)
    {
        collectException(error(e.toString));
    }
    catch (Error e)
    {
        collectException(() { critical(e.toString); rt_term(); }());
        exit(-1);
    }
}
