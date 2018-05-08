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

module kiss.util.uri;

import std.regex;
import std.conv : to;

class Uri
{
    private
    {
        string _uriString;
        string _scheme;
        string _host;
        ushort _port;
        string _path;
        string _username;
        string _password;
        string _query;
        string _fragment;

        bool _valid = false;
    }

    this(uriString)
    {
        this._uriString = uriString;
    }

    bool parse()
    {
        if (this._uriString)
        {
            return false;
        }

        auto uriReg = regex(r"/^([a-z0-9+.-]+):(?://(?:((?:[a-z0-9-._~!$&'()*+,;=:]|%[0-9A-F]{2})*)@)?((?:[a-z0-9-._~!$&'()*+,;=]|%[0-9A-F]{2})*)(?::(\d*))?(/(?:[a-z0-9-._~!$&'()*+,;=:@/]|%[0-9A-F]{2})*)?|(/?(?:[a-z0-9-._~!$&'()*+,;=:@]|%[0-9A-F]{2})+(?:[a-z0-9-._~!$&'()*+,;=:@/]|%[0-9A-F]{2})*)?)(?:\?((?:[a-z0-9-._~!$&'()*+,;=:/?@]|%[0-9A-F]{2})*))?(?:#((?:[a-z0-9-._~!$&'()*+,;=:/?@]|%[0-9A-F]{2})*))?$/i");
        auto m = match(this._uriString, uriReg);
        if (!m)
        {
            this._valid = false;
            return false;
        }

        this._scheme = m.captures[1];
        this._username = m.captures[2];
        this._password = m.captures[3];
        this._host = m.captures[4];
        this._port = (m.captures[5]).to!ushort;
        this._path = m.captures[6];
        this._query = m.captures[7];
        this._fragment = m.captures[8];

        this._valid = true;

        return true;
    }

    bool valid()
    {
        return this._valid;
    }

    @property void scheme(string scheme)
    {
        this._scheme = scheme;

        return this;
    }

    @property string scheme()
    {
        return this._scheme;
    }

    @property void username(string username)
    {
        this._username = username;

        return this;
    }

    @property string username()
    {
        return this._username;
    }

    @property void password(string password)
    {
        this._password = password;

        return this;
    }

    @property string password()
    {
        return this._password;
    }

    @property void host(string host)
    {
        this._host = host;

        return this;
    }

    @property string host()
    {
        return this._host;
    }

    @property void path(string path)
    {
        this._path = path;

        return this;
    }

    @property string path()
    {
        return this._path;
    }

    @property void query(string query)
    {
        this._query = query;

        return this;
    }

    @property string query()
    {
        return this._query;
    }

    @property void fragment(string fragment)
    {
        this._fragment = fragment;

        return this;
    }

    @property string fragment()
    {
        return this._fragment;
    }

    string toString()
    {
        return this._uriString;
    }
}
