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

module kiss.datetime.format;

import std.datetime : SysTime;
import std.datetime : DateTime;

// return unix timestamp
long time()
{
    import core.stdc.time : time;

    return time(null);
}

// return formated time string from timestamp
string date(string format, long timestamp = 0)
{
    long newTimestamp = timestamp > 0 ? timestamp : time();

    ubyte[] timeString;
    DateTime dt = cast(DateTime)(SysTime.fromUnixTime(newTimestamp));

    import std.conv : to;

    // format to ubyte
    foreach(c; format)
    {
        ubyte s;
        switch(c)
        {
        case 'Y':
            s = dt.year().to!ubyte;
            break;
        case 'm':
            s = dt.month().to!ubyte;
            break;
        case 'd':
            s = dt.day().to!ubyte;
            break;
        case 'H':
            s = dt.hour().to!ubyte;
            break;
        case 'i':
            s = dt.minute().to!ubyte;
            break;
        case 's':
            s = dt.second().to!ubyte;
            break;
        default:
            s = c;
            break;
        }

        timeString ~= s;
    }

    return cast(string)timeString;
}
