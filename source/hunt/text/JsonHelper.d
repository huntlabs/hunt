module hunt.text.JsonHelper;

import std.algorithm : map;
import std.array;
import std.conv;
import std.datetime;
import std.json;
import std.stdio;
import std.traits;
// import std.typecons;

import hunt.logging;
import hunt.util.serialize;

final class JsonHelper {

    static T getItemAs(T, bool canThrow = false)(ref const(JSONValue) json, string name, 
        T defaultValue = T.init) if (!is(T == void)) {
        JSONType jt = json.type();
        if (jt != JSON_TYPE.OBJECT) {            
            return handleException!(T, canThrow)(json, "wrong member type", defaultValue);
        }

        auto item = name in json;
        if (item is null) {            
            return handleException!(T, canThrow)(json, "wrong member type", defaultValue);
        }
        else {
            return getAs!T(*item); // , defaultValue
        }
    }

    /**
    Converts a `JSONValue` to an object of type `T` by filling its fields with the JSON's fields.
    */
    static T getAs(T, bool canThrow = false)(auto ref const(JSONValue) json, 
        T defaultValue = T.init) if ((is(T == class) || is(T == struct)) && !is(T == SysTime)) {
        JSONType jt = json.type();

        if (jt != JSON_TYPE.OBJECT) {
            return handleException!(T, canThrow)(json, "wrong object type", defaultValue);
        }

        static if (is(T == class)) {
            auto result = new T();
        }
        else {
            auto result = T();
        }

        foreach (member; __traits(allMembers, T)) {
            static if (__traits(getProtection, __traits(getMember, T,
                    member)) == "public" && !isType!(__traits(getMember, T,
                    member)) && !isSomeFunction!(__traits(getMember, T, member))) {
                try {
                    __traits(getMember, result, member) = getAs!(typeof(__traits(getMember,
                            result, member)), canThrow)(json[member]);
                }
                catch (JSONException e) {
                    return handleException!(T, canThrow)(json, e.msg, defaultValue);
                }
            }
        }

        return result;
    }

    static T getAs(T, bool canThrow = false)(auto ref const(JSONValue) json, 
        T defaultValue = T.init) if(is(T == SysTime)) {
  
        JSONType jt = json.type();
        if(jt == JSON_TYPE.string) {
            return SysTime.fromSimpleString(json.str);
        } else if(jt == JSON_TYPE.INTEGER) {
            return SysTime(json.integer);  // STD time
        } else {
            return handleException!(T, canThrow)(json, "wrong SysTime type", defaultValue);
        }
    }

    // static N getAs(N : Nullable!T, T, bool canThrow = false)(auto ref const(JSONValue) json) {

    //     return (json.type == JSON_TYPE.NULL) ? N() : getAs!T(json).nullable;
    // }

    static T getAs(T : JSONValue, bool canThrow = false)(auto ref const(JSONValue) json) {
        import std.typecons : nullable;
        return json.nullable;
    }

    static T getAs(T, bool canThrow = false)(auto ref const(JSONValue) json, T defaultValue = T.init) 
        if (isNumeric!T || isSomeChar!T) {

        switch (json.type) {
        case JSON_TYPE.NULL, JSON_TYPE.FALSE:
            return 0.to!T;

        case JSON_TYPE.TRUE:
            return 1.to!T;

        case JSON_TYPE.FLOAT:
            return json.floating.to!T;

        case JSON_TYPE.INTEGER:
            return json.integer.to!T;

        case JSON_TYPE.UINTEGER:
            return json.uinteger.to!T;

        case JSON_TYPE.STRING:
            try {
                return json.str.to!T;
            } catch(Exception ex) {
                return handleException!(T, canThrow)(json, ex.msg, defaultValue);
            }

        default:
            return handleException!(T, canThrow)(json, "", defaultValue);
        }
    }

    static T handleException(T, bool canThrow = false) (auto ref const(JSONValue) json, 
        string message, T defaultValue = T.init) {
        static if (canThrow) {
            throw new JSONException(json.toString() ~ " is not a " ~ T.stringof ~ " type");
        } else {
        version (HUNT_DEBUG)
            warningf(" %s is not a %s type. Using the defaults instead! \n Exception: %s",
                json.toString(), T.stringof, message);
            return defaultValue;
        }
    }

    static T getAs(T, bool canThrow = false)(auto ref const(JSONValue) json) if (isBoolean!T) {
        import std.json : JSON_TYPE;

        switch (json.type) {
        case JSON_TYPE.NULL, JSON_TYPE.FALSE:
            return false;

        case JSON_TYPE.FLOAT:
            return json.floating != 0;

        case JSON_TYPE.INTEGER:
            return json.integer != 0;

        case JSON_TYPE.UINTEGER:
            return json.uinteger != 0;

        case JSON_TYPE.STRING:
            return json.str.length > 0;

        default:
            return true;
        }
    }

    static T getAs(T, bool canThrow = false)(auto ref const(JSONValue) json, T defaultValue = T.init)
            if (isSomeString!T || is(T : string) || is(T : wstring) || is(T : dstring)) {

        static if (is(T == enum)) {
            foreach (member; __traits(allMembers, T)) {
                auto m = __traits(getMember, T, member);

                if (json.str == m) {
                    return m;
                }
            }
            return handleException!(T, canThrow)(json, 
                " is not a member of " ~ typeid(T).toString(), defaultValue);
        } else {
            return (json.type == JSON_TYPE.STRING ? json.str : json.toString()).to!T;
        }
    }

    static T getAs(T : U[], bool canThrow = false, U)(auto ref const(JSONValue) json, T defaultValue = T.init)
            if (isArray!T && !isSomeString!T && !is(T : string) && !is(T
                : wstring) && !is(T : dstring)) {

        switch (json.type) {
        case JSON_TYPE.NULL:
            return [];

        case JSON_TYPE.FALSE:
            return [getAs!U(JSONValue(false))];

        case JSON_TYPE.TRUE:
            return [getAs!U(JSONValue(true))];

        case JSON_TYPE.ARRAY:
            return json.array
                .map!(value => getAs!U(value))
                .array
                .to!T;

        case JSON_TYPE.OBJECT:
            // throw new JSONException(json.toString() ~ " is not a string type");
            return handleException!(T, canThrow)(json, "", defaultValue);

        default:
            return [getAs!U(json)];
        }
    }

    static T getAs(T : U[K], bool canThrow = false, U, K)(auto ref const(JSONValue) json, T defaultValue = T.init) 
        if (isAssociativeArray!T) {
        U[K] result;

        switch (json.type) {
        case JSON_TYPE.NULL:
            return result;

        case JSON_TYPE.OBJECT:
            foreach (key, value; json.object) {
                result[key.to!K] = getAs!U(value);
            }

            break;

        case JSON_TYPE.ARRAY:
            foreach (key, value; json.array) {
                result[key.to!K] = getAs!U(value);
            }

            break;

        default:
            // throw new JSONException(json.toString() ~ " is not an object type");
            return handleException!(T, canThrow)(json, "", defaultValue);
        }

        return result;
    }

    /// toJson

    // Nullable!JSONValue toJson(T)(T value) {
        // return JSONValue.init;
    //     return toJSON(t, level, ignore);
    // }

    static JSONValue toJson(T)(T value, uint level = uint.max, bool ignore = true)
            if ((is(T == class) || is(T == struct)) && !is(T == JSONValue) && !is(T == SysTime)) {
        import std.traits : isSomeFunction, isType;
        // import std.typecons : nullable;

        static if (is(T == class)) {
            if (value is null) {
                return JSONValue(null);
            }
        }

        auto result = JSONValue();

        foreach (member; __traits(allMembers, T)) {
            static if (__traits(getProtection, __traits(getMember, T,
                    member)) == "public" && !isType!(__traits(getMember, T,
                    member)) && !isSomeFunction!(__traits(getMember, T, member))) {
                auto json = toJson!(typeof(__traits(getMember, value, member)))(
                        __traits(getMember, value, member));

                if (!json.isNull) {
                    result[member] = json;
                }
            }
        }

        return result;
    }


    static JSONValue toJson(T)(T value, bool asInteger=true) if(is(T == SysTime)) {
        if(asInteger)
            return JSONValue(value.stdTime()); // STD time
        else 
            return JSONValue(value.toString());
    }

    // static Nullable!JSONValue toJson(N : Nullable!T, T)(N value) {
    //     return value.isNull ? Nullable!JSONValue() : Nullable!JSONValue(toJson!T(value.get()));
    // }

    static JSONValue toJson(T)(T value)
            if ((!is(T == class) && !is(T == struct)) || is(T == JSONValue)) {
        return JSONValue(value);
    }

    static JSONValue toJson(T : U[], U)(T value)
            if (isArray!T && !isSomeString!T && !is(T : string) && !is(T : wstring) && !is(T : dstring)) {
        import std.algorithm : map;

        return JSONValue(value.map!(item => toJson(item))()
                .map!(json => json.isNull ? JSONValue(null) : json).array);
    }

    static JSONValue toJson(T : U[K], U, K)(T value) if (isAssociativeArray!T) {
        auto result = JSONValue();

        foreach (key; value.keys) {
            auto json = toJson(value[key]);
            result[key.to!string] = json.isNull ? JSONValue(null) : json;
        }

        return result;
    }

}
