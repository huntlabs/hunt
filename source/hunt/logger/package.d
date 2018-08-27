module hunt.logger;

public import hunt.logger.logger;

import std.exception;
import hunt.logger;

import core.stdc.stdlib;
import core.runtime;

void catchAndLogException(E)(lazy E runer) @trusted nothrow
{
    try
    {
        runer();
    }
    catch (Exception e)
    {
        collectException(error(e.toString));
    }
    catch (Error e)
    {
        collectException(() { critical(e.toString); rt_term(); }());
        exit(-1);
    }
}
