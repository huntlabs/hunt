/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.Object;

/**
*/
interface IObject {

    bool opEquals(IObject o); 

    string toString();

    size_t toHash() @trusted nothrow;
}


/**
*/
class AbstractObject : IObject {

    bool opEquals(IObject o) {
        return opEquals(cast(Object)o);
    }

    override bool opEquals(Object o) {
        return this is o;
    }

    override string toString() {
        return super.toString();
    }

    override size_t toHash() @trusted nothrow {
        return super.toHash();
    }
}