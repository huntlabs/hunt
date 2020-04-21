module test.DeductionTest;

import common;
import hunt.logging.ConsoleLogger;

import std.traits;
import hunt.util.Traits;


class DeductionTest {

    void testArray() {
        ubyte[] data;
        deduce!(ubyte[], CaseSensitive.no)(data);

        GreetingBase[] greetings;
        deduce(greetings);
    }

    void testConstructor() {
        Class1 class1;
        deduce(class1);

        Exception ex;
        deduce(ex);
    }

 

    void test2() {
        assert(isByteArray!(ubyte[]));
        assert(!isByteArray!(int[]));
    }
}

import std.typecons;

/**
   Flag indicating whether a search is case-sensitive.
*/
alias CaseSensitive = Flag!"caseSensitive";


void deduce(T, CaseSensitive sensitive = CaseSensitive.yes)(T v) { // if(!is(T == class)) 
    trace(sensitive);
    static if(is(T : U[], U)) {
        tracef("Array, T: %s, U: %s", T.stringof, U.stringof);
    }

    static if(isBuiltinType!T) {
        tracef("isBuiltinType: %s", T.stringof);
    }

    static if(is(T == class)) {
        static if(is(typeof(new T()))) {
            tracef("class: %s, with this()", T.stringof);
        } else {
            tracef("class: %s, without this()", T.stringof);
        }
    }

}

// void deduce(T)(T v) if(is(T == class)) {

//     static if(is(typeof(new T()))) {
//         tracef("class: %s, with this()", T.stringof);
//     } else {
//         tracef("class: %s, without this()", T.stringof);
//     }
// }

void deduce(T : U[], U)(T v) if(is(U == class)) {
    infof("Array, T: %s, U: %s", T.stringof, U.stringof);
}

// void deduce(T)(T v) if(is(T : U[], U) && is(U == interface)) {
//     static if(is(T : U[], U)) {
//         tracef("T: %s, U: %s", T.stringof, U.stringof);
//     }

// }

class Class1 {
    @disable this() {

    }

    this(int id, string v) {

    }
}

