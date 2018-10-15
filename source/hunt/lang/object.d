module hunt.lang.object;

interface IObject {
    bool opEquals(Object o);
    string toString();
    size_t toHash() @trusted nothrow;
}
