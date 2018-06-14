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

import std.datetime.SysTime;
import std.datetime.DateTime;

// return unix timestamp
long time()
{
    return core.stdc.time.time(null);
}

// return formated time string from timestamp
string date(string format, long timestamp)
{
    long timestamp = timestamp > 0 ? timestamp : time();

    ubyte[] timeString;
    DateTime dt = cast(DateTime)(SysTime.fromUnixTime(timestamp));

    // format to ubyte
    foreach(c; format)
    {
        ubyte s;
        switch(c)
        {
        case 'Y':
            s = dt.year;
            break;
        case 'm':
            s = dt.month;
            break;
        case 'd':
            s = dt.day;
        case 'H':
            s = dt.houer;
            break;
        case 'm':
            s = dt.minute;
            break;
        case 'd':
            s = dt.second;
            break;
        default:
            s = c;
            break;
        }

        timeString ~= s;
    }

    return cast(string)timeString;
}
