/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2019  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.net
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.util.uri;

import std.regex;
import std.conv : to;

/**
*/
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

    this(string uri)
    {
        this._uriString = uri;
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

    @property Uri scheme(string scheme)
    {
        this._scheme = scheme;

        return this;
    }

    @property string scheme()
    {
        return this._scheme;
    }

    @property Uri username(string username)
    {
        this._username = username;

        return this;
    }

    @property string username()
    {
        return this._username;
    }

    @property Uri password(string password)
    {
        this._password = password;

        return this;
    }

    @property string password()
    {
        return this._password;
    }

    @property Uri host(string host)
    {
        this._host = host;

        return this;
    }

    @property string host()
    {
        return this._host;
    }

    @property Uri path(string path)
    {
        this._path = path;

        return this;
    }

    @property string path()
    {
        return this._path;
    }

    @property Uri query(string query)
    {
        this._query = query;

        return this;
    }

    @property string query()
    {
        return this._query;
    }

    @property Uri fragment(string fragment)
    {
        this._fragment = fragment;

        return this;
    }

    @property string fragment()
    {
        return this._fragment;
    }

    override string toString()
    {
        return this._uriString;
    }
}
