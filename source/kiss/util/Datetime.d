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

module kiss.util.Datetime;

// return unix timestamp
long time()
{
    return core.stdc.time.time(null);
}

// return formated time string from timestamp
string date(string format, long timestamp)
{
    long unixTime = timestamp > 0 ? timestamp : time();

    // format to ubyte

    return null;
}
