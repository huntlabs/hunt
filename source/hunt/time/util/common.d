module hunt.time.util.common;

import std.datetime;
import core.stdc.errno;
public import std.traits;
public import std.array;

import hunt.datetime;

class System
{
    static long currentTimeMillis()
    {
        return DateTimeHelper.currentTimeMillis();
    }

    static long currentTimeNsecs()
    {
        return convert!("hnsecs", "nsecs")(Clock.currStdTime() - (Date(1970, 1, 1) - Date.init).total!"hnsecs");
    }

    static string getSystemTimeZone()
    {
        return DateTimeHelper.getSystemTimeZoneId();
    }
}


string MakeGlobalVar(T)(string var, string init = null)
{
    string str;
    str ~= `__gshared ` ~ T.stringof ~ ` _` ~ var ~ `;`;
    str ~= "\r\n";
    if (init is null)
    {
        str ~= `public static ref ` ~ T.stringof ~ ` ` ~ var ~ `()
            {
                static if(isAggregateType!(`~ T.stringof ~`))
                {
                    if(_` ~ var ~ ` is null)
                    {
                        _`~ var ~ `= new ` ~ T.stringof ~ `();
                    }
                }
                else static if(isArray!(`~ T.stringof ~ `))
                {
                    if(_` ~ var ~ `.length == 0 )
                    {
                        _`~ var ~ `= new ` ~ T.stringof ~ `;
                    }
                }
                else
                {
                    if(_` ~ var ~ ` == `~ T.stringof.replace("[]","") ~`.init )
                    {
                        _`~ var ~ `= new ` ~ T.stringof ~ `();
                    }
                }
                
                return _` ~ var ~ `;
            }`;
    }
    else
    {
        str ~= `public static ref ` ~ T.stringof ~ ` ` ~ var ~ `()
            {
                static if(isAggregateType!(`~ T.stringof ~`))
                {
                    if(_` ~ var ~ ` is null)
                    {
                        _`~ var ~ `= ` ~ init ~ `;
                    }
                }
                else static if(isArray!(`~ T.stringof ~ `))
                {
                    if(_` ~ var ~ `.length == 0 )
                    {
                        _`~ var ~ `= ` ~ init ~ `;
                    }
                }
                else
                {
                    if(_` ~ var ~ ` == `~ T.stringof.replace("[]","") ~`.init )
                    {
                        _`~ var ~ `= ` ~ init ~ `;
                    }
                }
               
                return _` ~ var ~ `;
            }`;
    }

    return str;
}


