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

import std.algorithm : map;
import std.array;
import std.conv;
import std.datetime;
import std.json;
import std.stdio;
import std.traits;

import hunt.logging.ConsoleLogger;

/**
*/
interface JsonSerializable {

    JSONValue jsonSerialize();

    void jsonDeserialize(const(JSONValue) value);
}

/// attributes for json

/**
 * Excludes the field from both encoding and decoding.
 */
enum Exclude;

/**
 * Includes this even if it would otherwise be excluded.
 * If Exclude (or other UDA(@)) and Include are present value will be included.
 * Can also be used on @property methods to include them. (Be sure both the setter and getter exist!)
 * If used on a value of a base class value will be included.
 */
enum Include;

/**
 * Excludes the field from decoding, encode only.
 */
enum EncodeOnly;

/**
 * Excludes the field from encoding, decode only.
 */
enum DecodeOnly;


/**
*/
final class JsonSerializer {

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
            return fromJson!T(*item); // , defaultValue
        }
    }

    /**
    Converts a `JSONValue` to an object of type `T` by filling its fields with the JSON's fields.
    */
    static T fromJson(T, bool traverseBase = true, bool canThrow = false)
            (auto ref const(JSONValue) json, T defaultValue = T.init) 
            if (is(T == class)) {

        JSONType jt = json.type();

        if (jt != JSON_TYPE.OBJECT) {
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
    static T fromJson(T, bool canThrow = false)(auto ref const(JSONValue) json, T defaultValue = T.init) 
            if (is(T == struct) && !is(T == SysTime)) {

        JSONType jt = json.type();

        if (jt != JSON_TYPE.OBJECT) {
            return handleException!(T, canThrow)(json, "wrong object type", defaultValue);
        }

        auto result = T();

        try {
            static foreach (string member; FieldNameTuple!T) {
                    deserializeMembers!(member, false)(result, json);
            }
        } catch (JSONException e) {
            return handleException!(T, canThrow)(json, e.msg, defaultValue);
        }

        return result;
    }

    /**
    */
    static void deserializeObject(T, bool traverseBase = true)
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

    private static void deserializeMembers(string member, bool traverseBase = true, T)
        (ref T target, auto ref const(JSONValue) json) {

            static if(!hasUDA!(__traits(getMember, T, member), Exclude)) {

                alias memberType = typeof(__traits(getMember, T, member));

                static if(is(memberType == interface) && !is(memberType : JsonSerializable)) {
                    version(HUNT_DEBUG) warning("skipped a member: " ~ member);
                } else {
                    version(HUNT_DEBUG) tracef("setting: %s = %s", member, json[member].toString());
                    __traits(getMember, target, member) = fromJson!(memberType, false)(json[member]);
                }                    
            }
    }


    static T fromJson(T, bool canThrow = false)(auto ref const(JSONValue) json, 
        T defaultValue = T.init) if(is(T == interface) && is(T : JsonSerializable)) {

        auto jsonItemPtr = "type" in json;
        if(jsonItemPtr is null) {
            warningf("can't find 'type' item for interface %s", T.stringof);
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

    static T fromJson(T, bool canThrow = false)(auto ref const(JSONValue) json, 
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

    // static N fromJson(N : Nullable!T, T, bool canThrow = false)(auto ref const(JSONValue) json) {

    //     return (json.type == JSON_TYPE.NULL) ? N() : fromJson!T(json).nullable;
    // }

    static T fromJson(T : JSONValue, bool canThrow = false)(auto ref const(JSONValue) json) {
        import std.typecons : nullable;
        return json.nullable;
    }

    static T fromJson(T, bool canThrow = false)(auto ref const(JSONValue) json, T defaultValue = T.init) 
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

    static T fromJson(T, bool canThrow = false)(auto ref const(JSONValue) json) if (isBoolean!T) {
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
            return (json.type == JSON_TYPE.STRING ? json.str : json.toString()).to!T;
        }
    }

    static T fromJson(T : U[], bool canThrow = false, U)(auto ref const(JSONValue) json, 
            T defaultValue = T.init)
            if (isArray!T && !isSomeString!T && !is(T : string) && !is(T
                : wstring) && !is(T : dstring)) {

        switch (json.type) {
        case JSON_TYPE.NULL:
            return [];

        case JSON_TYPE.FALSE:
            return [fromJson!U(JSONValue(false))];

        case JSON_TYPE.TRUE:
            return [fromJson!U(JSONValue(true))];

        case JSON_TYPE.ARRAY:
            return json.array
                .map!(value => fromJson!U(value))
                .array
                .to!T;

        case JSON_TYPE.OBJECT:
            // throw new JSONException(json.toString() ~ " is not a string type");
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
        case JSON_TYPE.NULL:
            return result;

        case JSON_TYPE.OBJECT:
            foreach (key, value; json.object) {
                result[key.to!K] = fromJson!U(value);
            }

            break;

        case JSON_TYPE.ARRAY:
            foreach (key, value; json.array) {
                result[key.to!K] = fromJson!U(value);
            }

            break;

        default:
            // throw new JSONException(json.toString() ~ " is not an object type");
            return handleException!(T, canThrow)(json, "", defaultValue);
        }

        return result;
    }


    ///////////////////////////////////
    /// toJson
    ///////////////////////////////////

    // Nullable!JSONValue toJson(T)(T value) {
        // return JSONValue.init;
    //     return toJson(t, level, ignore);
    // }


    static JSONValue toJson(T, bool traverseBase = true, 
            bool includeMetaType = true)(T value) if (is(T == class)) {

        static if(is(T : JsonSerializable)) {
            return value.jsonSerialize();
        } else {
            return serializeObject!(T, traverseBase, includeMetaType)(value);
        }
    }

    static JSONValue serializeObject(T, bool traverseBase = true, 
            bool includeMetaType = true)(T value) if (is(T == class)) {
        import std.traits : isSomeFunction, isType;
        // import std.typecons : nullable;

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
                JSONValue superResult = toJson!(baseClasses[0], traverseBase, includeMetaType)(value);
                if(!superResult.isNull)
                    result["super"] = superResult;

            }
        }
        
        // current fields
		static foreach (string member; FieldNameTuple!T) {
            serializeMember!(member)(value, result);
        }

        return result;
    }

    static JSONValue toJson(T)(T value, uint level = uint.max)
            if (is(T == struct) && !is(T == SysTime)) {
        import std.traits : isSomeFunction, isType;
        // import std.typecons : nullable;

        static if(is(T == JSONValue)) {
            return value;
        } else {
            auto result = JSONValue();
            version(HUNT_DEBUG_MORE) pragma(msg, "======== current type: struct " ~ T.stringof);
                
            static foreach (string member; FieldNameTuple!T) {
                serializeMember!(member)(value, result);
            }

            return result;
        }
    }

    private static void serializeMember(string member, T)(T obj, ref JSONValue result) {
        version(HUNT_DEBUG_MORE) pragma(msg, "\tfield=" ~ member);
        
        static if(!hasUDA!(__traits(getMember, T, member), Exclude)) {
            alias memberType = typeof(__traits(getMember, T, member));

            static if(is(memberType == interface) && !is(memberType : JsonSerializable)) {
                version(HUNT_DEBUG) warning("skipped member(not JsonSerializable): " ~ member);
            } else {
                JSONValue json = toJson!(memberType)(__traits(getMember, obj, member));
                version(HUNT_DEBUG) {
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

    static JSONValue toJson(T)(T value)
    // if ((!is(T == class) && !is(T == struct) && !is(T == interface))) 
            if (isBuiltinType!T) {
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