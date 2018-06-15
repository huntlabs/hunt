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

// return unix timestamp
long time()
{
    import core.stdc.time : time;

    return time(null);
}

// return formated time string from timestamp
string date(string format, long timestamp = 0)
{
    import std.datetime : SysTime;
    import std.conv : to;

    long newTimestamp = timestamp > 0 ? timestamp : time();

    string timeString;

    SysTime st = SysTime.fromUnixTime(newTimestamp);

    // format to ubyte
    foreach(c; format)
    {
        switch(c)
        {
        case 'Y':
            timeString ~= st.year.to!string;
            break;
        case 'y':
            timeString ~= (st.year.to!string)[2..$];
            break;
        case 'm':
            timeString ~= st.month.to!string;
            break;
        case 'd':
            timeString ~= st.day < 10 ? "0" ~ st.day.to!string : st.day.to!string;
            break;
        case 'H':
            timeString ~= st.hour < 10 ? "0" ~ st.hour.to!string : st.hour.to!string;
            break;
        case 'i':
            timeString ~= st.minute < 10 ? "0" ~ st.minute.to!string : st.minute.to!string;
            break;
        case 's':
            timeString ~= st.second < 10 ? "0" ~ st.second.to!string : st.second.to!string;
            break;
        default:
            timeString ~= c;
            break;
        }
    }

    return timeString;
}
