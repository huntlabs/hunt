module hunt.time.util.common;

import std.datetime;

class System
{
    static long currentTimeMillis()
    {
        return convert!("hnsecs", "msecs")(Clock.currStdTime() - (Date(1970, 1, 1) - Date.init).total!"hnsecs");
    }
}
