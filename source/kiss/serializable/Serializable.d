module kiss.serializable.Serializable;

abstract Serializable(C)
{
    string toString()
    {
        return "class";
    }

    C copy()
    {
        return this;
    }

    ubyte[] serialize()
    {
        return null;
    }

    C unserialize()
    {
        return null;
    }
}
