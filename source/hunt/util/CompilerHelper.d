module hunt.util.CompilerHelper;


/**
 * 
 */
class CompilerHelper {

    static bool isGreaterThan(int ver) pure @safe @nogc nothrow {
        return __VERSION__ >= ver;
    }

    static bool isLessThan(int ver) pure @safe @nogc nothrow {
        return __VERSION__ <= ver;
    }
}
