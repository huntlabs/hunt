module kiss.config.read;

import kiss.config;

T readConfig(T)(BaseConfig config)
{
    auto rv = creatT!T();
    return rv;
}

T creatT(T)()
{
    static if(is(T == struct)){
        return T();
    } else {
        return new T();
    }
}