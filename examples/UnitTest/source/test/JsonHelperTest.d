module test.JsonHelperTest;

import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.util.UnitTest;
import hunt.text.JsonHelper;

// import hunt.util.serialize;
import std.json;
import std.datetime;

import std.conv;
import std.format;
import std.stdio;

class JsonHelperTest {

    @Test void testBasic01() {
        const jsonString = `{
            "integer": 42,
            "floating": 3.0,
            "text": "Hello world",
            "array": [0, 1, 2],
            "dictionary": {
                "key1": "value1",
                "key2": "value2",
                "key3": "value3"
            },
            "testStruct": {
                "uinteger": 16,
                "json": {
                    "key": "value"
                }
            }
        }`;

        const testClass = JsonHelper.getAs!TestClass(parseJSON(jsonString));
        assert(testClass.integer == 42);
        assert(testClass.floating == 3.0);
        assert(testClass.text == "Hello world");
        assert(testClass.array == [0, 1, 2]);
        const dictionary = ["key1" : "value1", "key2" : "value2", "key3" : "value3"];
        assert(testClass.dictionary == dictionary);
        assert(testClass.testStruct.uinteger == 16);
        assert(testClass.testStruct.json["key"].str == "value");
    }

    @Test void testGetAsClass01() {
        Greeting gt = new Greeting();
        gt.content = "Hello, world!";
        gt.creationTime = Clock.currTime;
        gt.currentTime = Clock.currStdTime;
        JSONValue jv = JsonHelper.toJson(gt);
        // trace("====>", jv, "====");

        Greeting gt1 = JsonHelper.getAs!(Greeting)(jv);
        // trace("gt====>", gt, "====");
        // trace("gt1====>", gt1, "====");
        assert(gt.content == gt1.content);
        assert(gt.creationTime == gt1.creationTime);
        assert(gt.currentTime == gt1.currentTime);

        JSONValue parametersInJson;
        parametersInJson["name"] = "Hunt";
        string parameterModel = JsonHelper.getItemAs!(string)(parametersInJson, "name");
        assert(parameterModel == "Hunt");
    }

    @Test void testGetAsSysTime() {
        SysTime st1 = Clock.currTime;
        JSONValue jv = JSONValue(st1.toString());
        // trace(jv);
        SysTime st2 = SysTime.fromSimpleString(jv.str);
        // trace(st2.toString());
        st2 = JsonHelper.getAs!(SysTime)(jv);
        // trace(st2.toString());
        assert(st1 == st2);
    }

    @Test void testConstParameter() {
        SysTime st1 = Clock.currStdTime;
        JSONValue jv;
        jv["stdtime"] = st1.stdTime;
        // trace(jv.toString());
        const(JSONValue)* ptr = "stdtime" in jv;
        if(ptr !is null) {
            SysTime st2 = JsonHelper.getAs!(SysTime)(*ptr);
            // trace(st2.toString());
            assert(st1 == st2);
        }
    }

    void testGetAsBasic02() {
        // auto json = JSONValue(42);
        // auto result = getAs!(Nullable!int)(json);
        // assert(!result.isNull && result.get() == json.integer);

        // json = JSONValue(null);
        // assert(JsonHelper.getAs!(Nullable!int)(json).isNull);

        assert(JsonHelper.getAs!JSONValue(JSONValue(42)) == JSONValue(42));
    }

    void testGetAsNumeric() {
        assert(JsonHelper.getAs!float(JSONValue(3.0)) == 3.0);
        assert(JsonHelper.getAs!int(JSONValue(42)) == 42);
        assert(JsonHelper.getAs!uint(JSONValue(42U)) == 42U);
        assert(JsonHelper.getAs!char(JSONValue('a')) == 'a');

        // quirky JSON cases

        assert(JsonHelper.getAs!int(JSONValue(null)) == 0);
        assert(JsonHelper.getAs!int(JSONValue(false)) == 0);
        assert(JsonHelper.getAs!int(JSONValue(true)) == 1);
        assert(JsonHelper.getAs!int(JSONValue("42")) == 42);
        assert(JsonHelper.getAs!char(JSONValue("a")) == 'a');
    }

    void testGetAsBool() {
        assert(JsonHelper.getAs!bool(JSONValue(false)) == false);
        assert(JsonHelper.getAs!bool(JSONValue(true)) == true);

        // quirky JSON cases

        assert(JsonHelper.getAs!bool(JSONValue(null)) == false);
        assert(JsonHelper.getAs!bool(JSONValue(0.0)) == false);
        assert(JsonHelper.getAs!bool(JSONValue(0)) == false);
        assert(JsonHelper.getAs!bool(JSONValue(0U)) == false);
        assert(JsonHelper.getAs!bool(JSONValue("")) == false);

        assert(JsonHelper.getAs!bool(JSONValue(3.0)) == true);
        assert(JsonHelper.getAs!bool(JSONValue(42)) == true);
        assert(JsonHelper.getAs!bool(JSONValue(42U)) == true);
        assert(JsonHelper.getAs!bool(JSONValue("Hello world")) == true);
        assert(JsonHelper.getAs!bool(JSONValue(new int[0])) == true);        
    }

    void testGetAsString() {
        enum Operation : string {
            create = "create",
            delete_ = "delete"
        }

        assert(JsonHelper.getAs!Operation(JSONValue("create")) == Operation.create);
        assert(JsonHelper.getAs!Operation(JSONValue("delete")) == Operation.delete_);

        auto json = JSONValue("Hello");
        assert(JsonHelper.getAs!string(json) == json.str);
        assert(JsonHelper.getAs!(char[])(json) == json.str);
        assert(JsonHelper.getAs!(wstring)(json) == "Hello"w);
        assert(JsonHelper.getAs!(wchar[])(json) == "Hello"w);
        assert(JsonHelper.getAs!(dstring)(json) == "Hello"d);
        assert(JsonHelper.getAs!(dchar[])(json) == "Hello"d);

        // beware of the fact that JSONValue treats chars as integers; this returns "97" and not "a"
        assert(JsonHelper.getAs!string(JSONValue('a')) != "a");
        assert(JsonHelper.getAs!string(JSONValue("a")) == "a");

        enum TestEnum : string {
            hello = "hello",
            world = "world"
        }

        assert(JsonHelper.getAs!TestEnum(JSONValue("hello")) == TestEnum.hello);
        assert(JsonHelper.getAs!TestEnum(JSONValue("world")) == TestEnum.world);

        // quirky JSON cases

        assert(JsonHelper.getAs!string(JSONValue(null)) == "null");
        assert(JsonHelper.getAs!string(JSONValue(false)) == "false");
        assert(JsonHelper.getAs!string(JSONValue(true)) == "true");
    }

    void testGetAsArray() {
        assert(JsonHelper.getAs!(int[])(JSONValue([0, 1, 2, 3])) == [0, 1, 2, 3]);

        // quirky JSON cases
        assert(JsonHelper.getAs!(byte[], false)(JSONValue([0, 1, 2, 3])) == [0, 1, 2, 3]);
        assert(JsonHelper.getAs!(int[])(JSONValue(null)) == []);
        assert(JsonHelper.getAs!(int[])(JSONValue(false)) == [0]);
        assert(JsonHelper.getAs!(bool[])(JSONValue(true)) == [true]);
        assert(JsonHelper.getAs!(float[])(JSONValue(3.0)) == [3.0]);
        assert(JsonHelper.getAs!(int[])(JSONValue(42)) == [42]);
        assert(JsonHelper.getAs!(uint[])(JSONValue(42U)) == [42U]);
        assert(JsonHelper.getAs!(string[])(JSONValue("Hello")) == ["Hello"]);
    }

    /// To Json

    void testNullableToJson()  {
        import std.typecons;
        // assert(JsonHelper.toJson(Nullable!int()) == Nullable!JSONValue());
        // assert(JsonHelper.toJson(Nullable!int(42)) == JSONValue(42));
    }

    void testBasicTypeToJson() {
        assert(JsonHelper.toJson(3.0) == JSONValue(3.0));
        assert(JsonHelper.toJson(42) == JSONValue(42));
        assert(JsonHelper.toJson(42U) == JSONValue(42U));
        assert(JsonHelper.toJson(false) == JSONValue(false));
        assert(JsonHelper.toJson(true) == JSONValue(true));
        assert(JsonHelper.toJson('a') == JSONValue('a'));
        assert(JsonHelper.toJson("Hello world") == JSONValue("Hello world"));
        assert(JsonHelper.toJson(JSONValue(42)) == JSONValue(42));
    }

    @Test void testSysTimeToJson() {
        SysTime st1 = Clock.currTime;
        JSONValue jv1 = JSONValue(st1.toString());
        JSONValue jv2 = JsonHelper.toJson(st1, false);
        
        assert(jv1 == jv2);
    }

    void testArrayToJson() {
        assert(JsonHelper.toJson([0, 1, 2]) == JSONValue([0, 1, 2]));
        assert(JsonHelper.toJson(["hello", "world"]) == JSONValue(["hello", "world"]));
    }

    void testAssociativeArrayToJson() {
        assert(JsonHelper.toJson(["hello" : 16, "world" : 42]) == JSONValue(["hello" : 16, "world" : 42]));
        assert(JsonHelper.toJson(['a' : 16, 'b' : 42]) == JSONValue(["a" : 16, "b" : 42]));
        assert(JsonHelper.toJson([0 : 16, 1 : 42]) == JSONValue(["0" : 16, "1" : 42]));
    }
}

class Greeting {
    private int id;

    // alias TestHandler = void delegate(string); // bug

    string content;
    SysTime creationTime;
    long currentTime;
    byte[] bytes;
    string[] members;

    override string toString() {
        string s = format("content=%s, creationTime=%s, currentTime=%s",
                content, creationTime, currentTime);
        return s;
    }
}


struct TestStruct
{
    uint uinteger;
    JSONValue json;

    // TestClass testClass;
}

class TestClass
{
    int integer;
    float floating;
    string text;
    int[] array;
    string[string] dictionary;
    TestStruct testStruct;
}