module hunt.util.traits;


mixin template GetConstantValues(T) if (is(T == struct) || is(T == class))
{
    static T[] values()
    {
        T[] r;
        enum s = __getValues!(r.stringof, T)();
        // pragma(msg, s);
        mixin(s);
        return r;
    }

    private static string __getValues(string name, T)()
    {
        string str;

        foreach (string memberName; __traits(derivedMembers, T))
        {
            // enum member = __traits(getMember, T, memberName);
            alias memberType = typeof(__traits(getMember, T, memberName));
            static if (is(memberType : T))
            {
                str ~= name ~ " ~= " ~ memberName ~ ";\r\n";
            }
        }

        return str;
    }

}


