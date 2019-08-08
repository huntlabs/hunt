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

module hunt.serialization.JsonSerializer;

import hunt.serialization.Common;
import hunt.logging.ConsoleLogger;
import hunt.util.Common;

import std.algorithm : map;
import std.array;
import std.conv;
import std.datetime;
import std.json;
import std.stdio;
import std.traits;


/**
*/
interface JsonSerializable {

    JSONValue jsonSerialize();

    void jsonDeserialize(const(JSONValue) value);
}


static if(CompilerHelper.isLessThan(2085)) {
    pragma(msg, "Warning: The minimum required version of D compiler is 2.086.");
} else {

/**
*/
final class JsonSerializer {

    static T getItemAs(T, bool canThrow = false)(ref const(JSONValue) json, string name, 
        T defaultValue = T.init) if (!is(T == void)) {
        if (json.type() != JSONType.object) {            
            return handleException!(T, canThrow)(json, "wrong member type", defaultValue);
        }

        auto item = name in json;
        if (item is null) {            
            return handleException!(T, canThrow)(json, "wrong member type", defaultValue);
        }
        else {
            return fromJson!T(*item); // , defaultValue
        }
    }

    static T fromJson(T, TraverseBase traverseBase = TraverseBase.yes, bool canThrow = false)
            (string json, T defaultValue = T.init) if (is(T == class)) {
        return fromJson!(T, traverseBase, canThrow)(parseJSON(json));
    }

    static T fromJson(T, bool canThrow = false)
            (string json, T defaultValue = T.init) if (!is(T == class)) {
        return fromJson!(T, canThrow)(parseJSON(json));
    }

    /**
    Converts a `JSONValue` to an object of type `T` by filling its fields with the JSON's fields.
    */
    static T fromJson(T, TraverseBase traverseBase = TraverseBase.yes, bool canThrow = false)
            (auto ref const(JSONValue) json, T defaultValue = T.init) 
            if (is(T == class) && is(typeof(new T()))) {

        if (json.type() != JSONType.object) {
            return handleException!(T, canThrow)(json, "wrong object type", defaultValue);
        }

        auto result = new T();

        static if(is(T : JsonSerializable)) {
            result.jsonDeserialize(json);
        } else {
            try {
                deserializeObject!(T, traverseBase)(result, json);
            } catch (JSONException e) {
                return handleException!(T, canThrow)(json, e.msg, defaultValue);
            }
        }

        return result;
    }

    /**
    */
    static T fromJson(T, bool canThrow = false)(
            auto ref const(JSONValue) json, T defaultValue = T.init) 
            if (is(T == struct) && !is(T == SysTime)) {

        JSONType jt = json.type();

        if (jt != JSONType.object) {
            return handleException!(T, canThrow)(json, "wrong object type", defaultValue);
        }

        auto result = T();

        try {
            static foreach (string member; FieldNameTuple!T) {
                    deserializeMembers!(member)(result, json);
            }
        } catch (JSONException e) {
            return handleException!(T, canThrow)(json, e.msg, defaultValue);
        }

        return result;
    }


    static void deserializeObject(T)(ref T target, auto ref const(JSONValue) json)
         if(is(T == struct)) {

        static foreach (string member; FieldNameTuple!T) {
            // current fields
            deserializeMembers!(member)(target, json);
        }
    }

    /**
    */
    static void deserializeObject(T, TraverseBase traverseBase = TraverseBase.yes)
            (T target, auto ref const(JSONValue) json) if(is(T == class)) {

        static foreach (string member; FieldNameTuple!T) {
            // current fields
            deserializeMembers!(member)(target, json);
        }

        // super fields
        alias baseClasses = BaseClassesTuple!T;
        static if(traverseBase && baseClasses.length >= 1) {
            auto jsonItemPtr = "super" in json;
            if(jsonItemPtr !is null) {
                deserializeObject!(baseClasses[0], traverseBase)(target, *jsonItemPtr);
            }
        }
    }

    private static void deserializeMembers(string member, T)
            (ref T target, auto ref const(JSONValue) json) {

        static if(!hasUDA!(__traits(getMember, T, member), Exclude)) {

            alias memberType = typeof(__traits(getMember, T, member));

            static if(is(memberType == interface) && !is(memberType : JsonSerializable)) {
                version(HUNT_DEBUG) warning("skipped a member: " ~ member);
            } else {
                auto jsonItemPtr = member in json;
                if(jsonItemPtr is null) {
                    version(HUNT_DEBUG) warningf("No data available for member: %s", member);
                } else {
                    version(HUNT_DEBUG_MORE) tracef("available data: %s = %s", member, jsonItemPtr.toString());
                    __traits(getMember, target, member) = fromJson!(memberType, false)(*jsonItemPtr);
                }
            }                    
        }
    }

    static T fromJson(T, bool canThrow = false)(
            auto ref const(JSONValue) json, 
            T defaultValue = T.init) 
            if(is(T == interface) && is(T : JsonSerializable)) {

        auto jsonItemPtr = "type" in json;
        if(jsonItemPtr is null) {
            warningf("Can't find 'type' item for interface %s", T.stringof);
            return T.init;
        }
        string typeId = jsonItemPtr.str;
        T t = cast(T) Object.factory(typeId);
        if(t is null) {
            warningf("Can't create instance for %s", T.stringof);
        }
        t.jsonDeserialize(json);
        return t;
    
    }

    static T fromJson(T, bool canThrow = false)(
            auto ref const(JSONValue) json, 
            T defaultValue = T.init) 
            if(is(T == SysTime)) {
  
        JSONType jt = json.type();
        if(jt == JSONType.string) {
            return SysTime.fromSimpleString(json.str);
        } else if(jt == JSONType.integer) {
            return SysTime(json.integer);  // STD time
        } else {
            return handleException!(T, canThrow)(json, "wrong SysTime type", defaultValue);
        }
    }

    // static N fromJson(N : Nullable!T, T, bool canThrow = false)(auto ref const(JSONValue) json) {

    //     return (json.type == JSONType.null_) ? N() : fromJson!T(json).nullable;
    // }

    static T fromJson(T : JSONValue, bool canThrow = false)(auto ref const(JSONValue) json) {
        import std.typecons : nullable;
        return json.nullable;
    }

    static T fromJson(T, bool canThrow = false)
            (auto ref const(JSONValue) json, T defaultValue = T.init) 
            if (isNumeric!T || isSomeChar!T) {

        switch (json.type) {
        case JSONType.null_, JSONType.false_:
            return 0.to!T;

        case JSONType.true_:
            return 1.to!T;

        case JSONType.float_:
            return json.floating.to!T;

        case JSONType.integer:
            return json.integer.to!T;

        case JSONType.uinteger:
            return json.uinteger.to!T;

        case JSONType.string:
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

    static T fromJson(T, bool canThrow = false)
            (auto ref const(JSONValue) json) if (isBoolean!T) {

        switch (json.type) {
        case JSONType.null_, JSONType.false_:
            return false;

        case JSONType.float_:
            return json.floating != 0;

        case JSONType.integer:
            return json.integer != 0;

        case JSONType.uinteger:
            return json.uinteger != 0;

        case JSONType.string:
            return json.str.length > 0;

        default:
            return true;
        }
    }

    static T fromJson(T, bool canThrow = false)(auto ref const(JSONValue) json, T defaultValue = T.init)
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
            return (json.type == JSONType.string ? json.str : json.toString()).to!T;
        }
    }

    static T fromJson(T : U[], bool canThrow = false, U)
            (auto ref const(JSONValue) json, 
            T defaultValue = T.init)
            if (isArray!T && !isSomeString!T && !is(T : string) && !is(T
                : wstring) && !is(T : dstring)) {

        switch (json.type) {
        case JSONType.null_:
            return [];

        case JSONType.false_:
            return [fromJson!U(JSONValue(false))];

        case JSONType.true_:
            return [fromJson!U(JSONValue(true))];

        case JSONType.array:
            return json.array
                .map!(value => fromJson!U(value))
                .array
                .to!T;

        case JSONType.object:
            return handleException!(T, canThrow)(json, "", defaultValue);

        default:
            return [fromJson!U(json)];
        }
    }

    static T fromJson(T : U[K], bool canThrow = false, U, K)(
            auto ref const(JSONValue) json, T defaultValue = T.init) 
            if (isAssociativeArray!T) {
        
        U[K] result;

        switch (json.type) {
        case JSONType.null_:
            return result;

        case JSONType.object:
            foreach (key, value; json.object) {
                result[key.to!K] = fromJson!U(value);
            }

            break;

        case JSONType.array:
            foreach (key, value; json.array) {
                result[key.to!K] = fromJson!U(value);
            }

            break;

        default:
            return handleException!(T, canThrow)(json, "", defaultValue);
        }

        return result;
    }


    ///////////////////////////////////
    /// toJson
    ///////////////////////////////////

    static JSONValue toJson(T, 
            TraverseBase traverseBase = TraverseBase.yes, 
            OnlyPublic onlyPublic = OnlyPublic.no, 
            IncludeMeta includeMeta = IncludeMeta.yes)
            (T value) if (is(T == class)) {

        version(HUNT_DEBUG_MORE) 
        tracef("traverseBase = %s, onlyPublic = %s, includeMeta = %s",
             traverseBase, onlyPublic, includeMeta);

        static if(is(T : JsonSerializable)) {
            return value.jsonSerialize();
        } else {
            return serializeObject!(T, traverseBase, onlyPublic, includeMeta)(value);
        }
    }

    static JSONValue serializeObject(T, 
            TraverseBase traverseBase = TraverseBase.yes, 
            OnlyPublic onlyPublic = OnlyPublic.no, 
            IncludeMeta includeMeta = IncludeMeta.yes) 
            (T value) if (is(T == class)) {
        import std.traits : isSomeFunction, isType;
        // import std.typecons : nullable;

        version(HUNT_DEBUG_MORE) 
        tracef("traverseBase = %s, onlyPublic = %s, includeMeta = %s",
             traverseBase, onlyPublic, includeMeta);

        if (value is null) {
            version(HUNT_DEBUG) warning("value is null");
            return JSONValue(null);
        }

        auto result = JSONValue();
        version(HUNT_DEBUG_MORE) pragma(msg, "======== current type: class " ~ T.stringof);

        // super fields
        static if(traverseBase) {
            alias baseClasses = BaseClassesTuple!T;
            static if(baseClasses.length >= 1) {
                JSONValue superResult = toJson!(baseClasses[0], traverseBase, onlyPublic, includeMeta)(value);
                if(!superResult.isNull)
                    result["super"] = superResult;

            }
        }
        
        // current fields
		static foreach (string member; FieldNameTuple!T) {
            serializeMember!(member, T, onlyPublic)(value, result);
        }

        return result;
    }

    static JSONValue toJson(T, OnlyPublic onlyPublic = OnlyPublic.no)(T value)
            if (is(T == struct) && !is(T == SysTime)) {
        import std.traits : isSomeFunction, isType;
        // import std.typecons : nullable;

        static if(is(T == JSONValue)) {
            return value;
        } else {
            auto result = JSONValue();
            version(HUNT_DEBUG_MORE) pragma(msg, "======== current type: struct " ~ T.stringof);
                
            static foreach (string member; FieldNameTuple!T) {
                serializeMember!(member, T, onlyPublic)(value, result);
            }

            return result;
        }
    }

    private static void serializeMember(string member, 
            T, OnlyPublic onlyPublic = OnlyPublic.no)
            (T obj, ref JSONValue result) {

        version(HUNT_DEBUG_MORE) pragma(msg, "\tfield=" ~ member);

        alias currentMember = __traits(getMember, T, member);

        static if(onlyPublic) {
            static if (__traits(getProtection, currentMember) == "public") {
                enum canSerialize = true;
            } else {
                enum canSerialize = false;
            }
        } else static if(hasUDA!(currentMember, Exclude)) {
            enum canSerialize = false;
        } else {
            enum canSerialize = true;
        }
        
        version(HUNT_DEBUG_MORE) tracef("name: %s, onlyPublic: %s", member, onlyPublic);

        static if(canSerialize) {
            alias memberType = typeof(currentMember);

            static if(is(memberType == interface) && !is(memberType : JsonSerializable)) {
                version(HUNT_DEBUG) warning("skipped a member(not JsonSerializable): " ~ member);
            } else {
                JSONValue json = toJson!(memberType)(__traits(getMember, obj, member));
                version(HUNT_DEBUG_MORE) {
                    tracef("name: %s, value: %s", member, json.toString());
                }
                if (!json.isNull) {
                        // trace(result);
                    if(!result.isNull) {
                        auto jsonItemPtr = member in result;
                        if(jsonItemPtr !is null) {
                            warning("overrided field: " ~ member);
                        }
                    }
                    result[member] = json;
                }

            }
        } else {
            version(HUNT_DEBUG_MORE) tracef("skipped member, name: %s", member);
        }
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

    // static JSONValue toJson(T)(T value) if (is(T == JSONValue)) {
    //     return value;
    // }

    static JSONValue toJson(T)(T value) if (is(T == interface) && is(T : JsonSerializable)) {
        JSONValue v = value.jsonSerialize();
        v["type"] = typeid(cast(Object)value).name;
        return v;
    }

    static JSONValue toJson(T)(T value) if (isBasicType!T) {
        return JSONValue(value);
    }

    static JSONValue toJson(T)(T value)
            if (is(T : U[], U) && (isBasicType!U || isSomeString!U)) {
        return JSONValue(value);
    }

    static JSONValue toJson(TraverseBase traverseBase = TraverseBase.yes, 
            OnlyPublic onlyPublic = OnlyPublic.no, 
            T : U[], U)
            (T value) 
            if(is(T : U[], U) && is(U == class)) {

        return JSONValue(value.map!(item => toJson!(U, traverseBase, onlyPublic)(item))()
                .map!(json => json.isNull ? JSONValue(null) : json).array);
    }
    
    static JSONValue toJson(T : U[], U)(T value) if(is(U == struct)) {
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
}