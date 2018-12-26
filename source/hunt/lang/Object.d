module hunt.lang.Object;

/**
*/
interface IObject {

    bool opEquals(const(IObject) o) const; 

    string toString();

    size_t toHash() @trusted nothrow;
}


/**
*/
class AbstractObject : IObject {

    bool opEquals(const(IObject) o) const {
        return opEquals(cast(Object)o);
    }

    override bool opEquals(const(Object) o) const {
        return this is o;
    }

    override string toString() {
        return super.toString();
    }

    override size_t toHash() @trusted nothrow {
        return super.toHash();
    }
}