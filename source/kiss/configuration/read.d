module kiss.configuration.read;

import kiss.configuration;

struct ConfigItem
{
    this(bool opt){
        optional = opt;
    }
    this(string str, bool opt = false){
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

        static if (hasUDA!(T, ConfigItem)){
            enum name = getUDAs!(T, ConfigItem)[0].name;
            static if(name.length > 0){
                return redConfigVale(config.value(name));
            } else {
                return redConfigVale(config.topValue);
            }
        } else {
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
            static if(is(T == struct)){
                return T();
            } else {
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

        string tColumnName(string column,string name)
        {
        // string column = getUDAs!(U, Column)[0].name;
            if(column.length == 0)
                return name;
            else
                return column;
        }

        string str;
        foreach(memberName; __traits(allMembers, T))
        {
            //alias CurrtType = typeof( __traits(getMember,T, memberName) );
            static if(__traits(compiles,__traits(getMember,T, memberName)) && 
                                hasUDA!(__traits(getMember,T, memberName),ConfigItem))
            {
                auto item = getUDAs!((__traits(getMember,T, memberName)), ConfigItem)[0];
                string name = tColumnName(item.name, memberName);
                static if(is(typeof( __traits(getMember,T, memberName) ) == struct) || 
                                is(typeof( __traits(getMember,T, memberName) ) == class)){
                    if(item.optional){
                        str ~= "collectException("~ typeof( __traits(getMember,T, memberName) ).stringof 
                                ~ ".redConfigVale(value.value(\"" ~ name ~ "\")),rv. "  ~ memberName ~ ");\n"; 
                    } else {
                        str ~= "rv." ~ memberName ~ " = " ~ typeof( __traits(getMember,T, memberName) ).stringof 
                                ~ ".redConfigVale(value.value(\"" ~ name ~ "\"));\n";
                    }
                } else {
                    if(item.optional){
                        str ~= "collectException(value.value(\""~ name ~ "\").value().as!" 
                                ~ typeof( __traits(getMember,T, memberName) ).stringof ~ "(),rv. "  ~ memberName ~ ");\n"; 
                    } else {
                        str ~= "rv." ~ memberName ~ " = value.value(\"" ~ name ~ "\").value().as!" 
                                ~ typeof( __traits(getMember,T, memberName) ).stringof ~ "();\n";
                    }
                }
            }
        }
        return str;
    }

}