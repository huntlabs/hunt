module kiss.util.configuration;

import std.conv;
import std.exception;
import std.array;
import std.stdio;
import std.string;
import std.traits;

import std.experimental.logger;

class ConfFormatException : Exception
{
    mixin basicExceptionCtors;
}

class NoValueHasException : Exception
{
    mixin basicExceptionCtors;
}

interface BaseConfigValue
{
    @property string value();
    @property BaseConfigValue value(string key);
    //BaseConfigValue opDispatch(string s)();
}

interface BaseConfig
{
    BaseConfigValue value(string key);
    @property BaseConfigValue topValue();
    //BaseConfigValue opDispatch(string s)();
}

auto as(T)(string value, T iv = T.init)
{
    static if (is(T == bool))
    {
        if (value.length == 0 || value == "false" || value == "0")
            return false;
        else
            return true;
    }
    else static if (isNumeric!(T))
    {
        if (value.length == 0)
            return iv;
        else
            return to!T(value);
    }
    else
    {
        if (value.length == 0)
            return iv;
        else
            return cast(T) value;
    }
}

class ConfigurationValue : BaseConfigValue
{
    override @property BaseConfigValue value(string name)
    {
        auto v = _map.get(name, null);
        enforce!NoValueHasException(v, format(" %s is not in config! ", name));
        return v;
    }

    override @property string value()
    {
        return _value;
    }

    auto opDispatch(string s)()
    {
        return cast(ConfigurationValue)(value(s));
    }

private:
    string _value;
    ConfigurationValue[string] _map;
}

class Configuration : BaseConfig
{
    this(string filename, string section = "")
    {
        _section = section;
        loadConfig(filename);
    }

    override BaseConfigValue value(string name)
    {
        return _value.value(name);
    }

    override @property BaseConfigValue topValue()
    {
        return _value;
    }

    auto opDispatch(string s)()
    {
        return _value.opDispatch!(s)();
    }

private:
    void loadConfig(string filename)
    {
        _value = new ConfigurationValue();

        import std.file;

        if (!exists(filename))
            return;
        import std.format;

        auto f = File(filename, "r");
        if (!f.isOpen())
            return;
        scope (exit)
            f.close();
        string section = "";
        int line = 1;
        while (!f.eof())
        {
            scope (exit)
                line += 1;
            string str = f.readln();
            str = strip(str);
            if (str.length == 0)
                continue;
            if (str[0] == '#' || str[0] == ';')
                continue;
            auto len = str.length - 1;
            if (str[0] == '[' && str[len] == ']')
            {
                section = str[1 .. len].strip;
                continue;
            }
            if (section != _section && section != "")
                continue; // 不是自己要读取的分段，就跳过
            auto site = str.indexOf("=");
            enforce!ConfFormatException((site > 0),
                    format("the format is erro in file %s, in line %d", filename, line));
            string key = str[0 .. site].strip;
            setValue(split(key, '.'), str[site + 1 .. $].strip);
        }
    }

    void setValue(string[] list, string value)
    {
        auto cvalue = _value;
        foreach (ref str; list)
        {
            if (str.length == 0)
                continue;
            auto tvalue = cvalue._map.get(str, null);
            if (tvalue is null)
            { // 不存在就追加一个
                tvalue = new ConfigurationValue();
                cvalue._map[str] = tvalue;
            }
            cvalue = tvalue;
        }
        if (cvalue is _value)
            return;
        cvalue._value = value;
    }

private:
    string _section;
    ConfigurationValue _value;
}

version (unittest)
{
    import kiss.configuration.read;

    @ConfigItem("app")
    class TestConfig
    {
        @ConfigItem()
        string test;
        @ConfigItem()
        double time;

        @ConfigItem("http")
        TestHttpConfig listen;

        @ConfigItem("optial", true)
        int optial = 500;

        @ConfigItem(true)
        int optial2 = 500;

        mixin ReadConfig!TestConfig;
    }

    @ConfigItem("HTTP")
    struct TestHttpConfig
    {
        @ConfigItem("listen")
        int value;

        mixin ReadConfig!TestHttpConfig;
    }
}

unittest
{
    import std.stdio;
    import FE = std.file;

    FE.write("test.config", "app.http.listen = 100 \nhttp.listen = 100 \napp.test = \napp.time = 0.25 \n# this is  \n ; start dev\n [dev]\napp.test = dev");
    auto conf = new Configuration("test.config");
    assert(conf.http.listen.value.as!long() == 100);
    assert(conf.app.test.value() == "");

    auto confdev = new Configuration("test.config", "dev");
    long tv = confdev.http.listen.value.as!long;
    assert(tv == 100);
    assert(confdev.http.listen.value.as!long() == 100);
    writeln("----------", confdev.app.test.value());
    string tvstr = cast(string) confdev.app.test.value;

    assert(tvstr == "dev");
    assert(confdev.app.test.value() == "dev");
    bool tvBool = confdev.app.test.value.as!bool;
    assert(tvBool);

    string str;
    auto e = collectException!NoValueHasException(confdev.app.host.value(), str);
    assert(e && e.msg == " host is not in config! ");

    TestConfig test = TestConfig.readConfig(confdev);
    assert(test.test == "dev");
    assert(test.time == 0.25);
    assert(test.listen.value == 100);
    assert(test.optial == 500);
    assert(test.optial2 == 500);
}

struct ConfigItem
{
    this(bool opt)
    {
        optional = opt;
    }

    this(string str, bool opt = false)
    {
        name = str;
        optional = opt;
    }

    string name;
    bool optional = false;
}

mixin template ReadConfig(T)
{
    static T readConfig(BaseConfig config)
    {
        import std.traits;
        import kiss.traits;

        static if (hasUDA!(T, ConfigItem))
        {
            enum name = getUDAs!(T, ConfigItem)[0].name;
            static if (name.length > 0)
            {
                return redConfigVale(config.value(name));
            }
            else
            {
                return redConfigVale(config.topValue);
            }
        }
        else
        {
            static assert(0, "the Type is not a config type!");
        }
    }

    static T redConfigVale(BaseConfigValue value)
    {
        import std.traits;
        import kiss.traits;
        import std.exception;

        T creatT(T)()
        {
            static if (is(T == struct))
            {
                return T();
            }
            else
            {
                return new T();
            }
        }

        auto rv = creatT!T();
        mixin(buildSetFunction!T());
        return rv;
    }

    static string buildSetFunction(T)()
    {
        import std.traits;
        import kiss.traits;

        string tColumnName(string column, string name)
        {
            // string column = getUDAs!(U, Column)[0].name;
            if (column.length == 0)
                return name;
            else
                return column;
        }

        string str;
        foreach (memberName; __traits(allMembers, T))
        {
            //alias CurrtType = typeof( __traits(getMember,T, memberName) );
            static if (__traits(compiles, __traits(getMember, T, memberName))
                    && hasUDA!(__traits(getMember, T, memberName), ConfigItem))
            {
                auto item = getUDAs!((__traits(getMember, T, memberName)), ConfigItem)[0];
                string name = tColumnName(item.name, memberName);
                static if (is(typeof(__traits(getMember, T, memberName)) == struct)
                        || is(typeof(__traits(getMember, T, memberName)) == class))
                {
                    if (item.optional)
                    {
                        str ~= "collectException(" ~ typeof(__traits(getMember, T, memberName))
                            .stringof ~ ".redConfigVale(value.value(\"" ~ name
                            ~ "\")),rv. " ~ memberName ~ ");\n";
                    }
                    else
                    {
                        str ~= "rv." ~ memberName ~ " = " ~ typeof(__traits(getMember, T, memberName))
                            .stringof ~ ".redConfigVale(value.value(\"" ~ name ~ "\"));\n";
                    }
                }
                else
                {
                    if (item.optional)
                    {
                        str ~= "collectException(value.value(\"" ~ name ~ "\").value().as!" ~ typeof(__traits(getMember,
                                T, memberName)).stringof ~ "(),rv. " ~ memberName ~ ");\n";
                    }
                    else
                    {
                        str ~= "rv." ~ memberName ~ " = value.value(\"" ~ name ~ "\").value().as!" ~ typeof(
                                __traits(getMember, T, memberName)).stringof ~ "();\n";
                    }
                }
            }
        }
        return str;
    }

}
