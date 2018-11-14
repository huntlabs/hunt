module hunt.util.JsonHelper;

import std.array;
import std.conv;
import std.json;
import std.string;
import std.stdio;

import hunt.logging;
import hunt.util.serialize;

final class JsonHelper {

    static T getItemAs(T)(ref JSONValue json, string name, T defaultValue = T.init)
            if (!is(T == void)) {
        JSONType jt = json.type();
        if (jt != JSON_TYPE.OBJECT) {
            warningf("Can't handle json type: %s, target type: %s", jt, T.stringof);
            return defaultValue;
        }

        auto item = name in json;
        if (item is null) {
            version (HUNT_DEBUG)
                warningf("Can't get data for %s. Using the defaults instead!", name);
            return defaultValue;
        } else {
            return getAs!T(*item, defaultValue);
        }

    }

    static T getAs(T)(auto ref const(JSONValue) json, T defaultValue = T.init)
            if (!is(T == void)) {
        JSONType jt = json.type();
        static if (is(T == class) || is(T == struct)) {
            if(jt == JSON_TYPE.OBJECT) {
                return toObject!T(json);
            } else {
                version (HUNT_DEBUG)
                warningf("Can't handle json type of non-OBJECT. Using the defaults instead!");
                return defaultValue;
            }
        } else {
            if (jt == JSON_TYPE.STRING) {
                static if (is(T == string))
                    return json.str;
                else
                    return to!T(json.str);
            } else if (jt == JSON_TYPE.INTEGER) {
                return to!T(json.integer);
            } else if (jt == JSON_TYPE.UINTEGER) {
                return to!T(json.uinteger);
            } else if (jt == JSON_TYPE.ARRAY) {
                // TODO: Tasks pending completion -@zxp at 11/14/2018, 11:15:50 AM
                // 
                version (HUNT_DEBUG)
                    warningf("Can't handle jsont type of ARRAY. Using the defaults instead!");
                return defaultValue;
            } else {
                warningf("Can't handle json type: %s, target type: %s", jt, T.stringof);
                return defaultValue;
            }
        }
    }
}
