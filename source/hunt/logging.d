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
module hunt.logging;

import std.exception;

import core.stdc.stdlib;
import core.runtime;

import std.concurrency;
import std.parallelism;
import std.traits;
import std.array;
import std.string;
import std.stdio;
import std.datetime;
import std.format;
import std.range;
import std.conv;
import std.regex;
import std.path;
import std.typecons;
import std.file;
import std.algorithm.iteration;
import core.thread;

import hunt.util.thread;

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



