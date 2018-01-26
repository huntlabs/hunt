module kiss.configuration;

import std.exception;
import std.traits;
import std.conv;

class ConfFormatException : Exception
{
	mixin basicExceptionCtors;
}

class NoValueHasException : Exception
{
	mixin basicExceptionCtors;
}

interface  BaseConfigValue {
    @property string value();
    @property BaseConfigValue value(string key);
    //BaseConfigValue opDispatch(string s)();
}

interface  BaseConfig {
    BaseConfigValue value(string key);
    @property BaseConfigValue topValue();
    //BaseConfigValue opDispatch(string s)();
}

auto as(T)(string value,T iv = T.init)
{
    static if(is(T == bool)){
        if(value.length == 0 || value == "false" || value == "0")
            return false;
        else
            return true;
    } else static if(isNumeric!(T)){
        if(value.length == 0)
            return iv;
        else
            return to!T(value);
    } else {
        if(value.length == 0)
            return iv;
        else
            return cast(T)value;
    }
}