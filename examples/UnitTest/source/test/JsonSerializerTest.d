module test.JsonSerializerTest;

import common;
import hunt.util.Common;

import test.quartz.JobDataMap;
import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.util.UnitTest;
import hunt.serialization.Common;
import hunt.serialization.JsonSerializer;

import std.json;
import std.datetime;

import std.conv;
import std.format;
import std.stdio;

class JsonSerializerTest {

//     @Test void testBasic01() {
//         const jsonString = `{
//             "integer": 42,
//             "floating": 3.0,
//             "text": "Hello world",
//             "array": [0, 1, 2],
//             "dictionary": {
//                 "key1": "value1",
//                 "key2": "value2",
//                 "key3": "value3"
//             },
//             "testStruct": {
//                 "uinteger": 16,
//                 "json": {
//                     "key": "value"
//                 }
//             }
//         }`;

//         const testClass = JsonSerializer.fromJson!TestClass(parseJSON(jsonString));
//         assert(testClass.integer == 42);
//         assert(testClass.floating == 3.0);
//         assert(testClass.text == "Hello world");
//         assert(testClass.array == [0, 1, 2]);
//         const dictionary = ["key1" : "value1", "key2" : "value2", "key3" : "value3"];
//         assert(testClass.dictionary == dictionary);
//         assert(testClass.testStruct.uinteger == 16);
//         assert(testClass.testStruct.json["key"].str == "value");

//         TestClass testClass02 = new TestClass();
//         testClass02.integer = 12;
//         testClass02.floating = 23.4f;

//         string s = JsonSerializer.toJson(testClass02).toPrettyString();
//         // writeln(s);
//     }

//     void testMemberMissing() {
//         GreetingBase greeting = new GreetingBase(1, "Hello");
//         JSONValue json = JsonSerializer.toJson(greeting);
//         assert(json.toString() == `{"content":"Hello","id":1}`);

//         // 
//         enum string jsonStr = `{"content":"Hello World"}`;

//         GreetingBase greeting1 = JsonSerializer.fromJson!GreetingBase(jsonStr);
//         trace(greeting1.toString());

//         assert(greeting1.id == 0);
//         assert(greeting1.getContent() == "Hello World");

//         // 
//         JsonSerializer.deserializeObject(greeting, parseJSON(jsonStr));
//         trace(greeting.toString());
//         assert(greeting.getContent() == "Hello World");

//         // 
//         GreetingModel greetingModel = JsonSerializer.fromJson!GreetingModel(jsonStr);
//         assert(greetingModel.id == 0);
//         assert(greetingModel.content == "Hello World");
//         trace(greetingModel);

//         //
//         greetingModel.id = 10;
//         greetingModel.content = "new world";

//         JsonSerializer.deserializeObject(greetingModel, parseJSON(jsonStr));
//         trace(greetingModel);
//         assert(greetingModel.id == 10);
//         assert(greetingModel.content == "Hello World");
//     }


//     @Test void testGetAsClass01() {
//         Greeting gt = new Greeting();
//         gt.setPrivateMember("private member");
//         gt.id = 123;
//         gt.content = "Hello, world!";
//         gt.creationTime = Clock.currTime;
//         gt.currentTime = Clock.currStdTime;
//         gt.setColor("Red");
//         gt.setContent("Hello");
//         JSONValue jv = JsonSerializer.toJson(gt);
//         // trace("====>", jv.toPrettyString(), "====");

//         Greeting gt1 = JsonSerializer.fromJson!(Greeting)(jv);
//         // trace("gt====>", gt, "====");
//         // trace("gt1====>", gt1, "====");
//         assert(gt1 !is null);
//         // trace(gt1.getContent());

//         assert(gt.getPrivateMember == gt1.getPrivateMember);
//         assert(gt.id == gt1.id);
//         assert(gt.content == gt1.content);
//         assert(gt.creationTime == gt1.creationTime);
//         assert(gt.currentTime != gt1.currentTime);
//         assert(0 == gt1.currentTime);
//         assert(gt.getColor() == gt1.getColor());
//         assert(gt1.getColor() == "Red");
//         assert(gt.getContent() == gt1.getContent());
//         assert(gt1.getContent() == "Hello");

//         JSONValue parametersInJson;
//         parametersInJson["name"] = "Hunt";
//         string parameterModel = JsonSerializer.getItemAs!(string)(parametersInJson, "name");
//         assert(parameterModel == "Hunt");
//     }

//     void testMetaType() {

//         Greeting gt = new Greeting();
//         JSONValue jv = JsonSerializer.toJson!(OnlyPublic.no, 
//             TraverseBase.yes, IncludeMeta.no)(gt);
//         // trace(jv.toPrettyString());

//         auto itemPtr = MetaTypeName in jv;
//         assert(itemPtr is null);

//         itemPtr = "super" in jv;
//         assert(itemPtr !is null);

//         itemPtr = MetaTypeName in *itemPtr;
//         assert(itemPtr is null);

// /* -------------------------IncludeMeta.yes----------------------------------- */

//         jv = JsonSerializer.toJson!(OnlyPublic.no, 
//             TraverseBase.yes, IncludeMeta.yes)(gt);
//         // trace(jv.toPrettyString());

//         itemPtr = MetaTypeName in jv;
//         assert(itemPtr !is null);

//         itemPtr = "super" in jv;
//         assert(itemPtr !is null);

//         itemPtr = MetaTypeName in *itemPtr;
//         assert(itemPtr !is null);
//     }

//     void testComplexMembers() {
        
//         Greeting gt = new Greeting();
//         gt.setPrivateMember("private member");
//         gt.id = 123;
//         gt.content = "Hello, world!";
//         gt.creationTime = Clock.currTime;
//         gt.currentTime = Clock.currStdTime;
//         gt.setColor("Red");
//         gt.setContent("Hello");
//         gt.addGuest("gest02", 25);
//         JSONValue jv = JsonSerializer.toJson!(OnlyPublic.no, 
//             TraverseBase.yes, IncludeMeta.no)(gt);
//         // trace(jv.toPrettyString());

//         Greeting gt1 = JsonSerializer.fromJson!(Greeting)(jv);
//         // trace("gt====>", gt, "====");
//         // trace("gt1====>", gt1, "====");
//         assert(gt1 !is null);
//         // trace(gt1.getContent());

//         JSONValue jv1 = JsonSerializer.toJson!(OnlyPublic.no, 
//             TraverseBase.yes, IncludeMeta.no)(gt1);
//         // trace(jv1.toPrettyString());

//         // trace(jv.toString());
//         // trace(jv1.toString());
//         assert(jv.toString() == jv1.toString());

//         assert(gt.getPrivateMember == gt1.getPrivateMember);
//         assert(gt.id == gt1.id);
//         assert(gt.content == gt1.content);
//         assert(gt.creationTime == gt1.creationTime);
//         assert(gt.currentTime != gt1.currentTime);
//         assert(0 == gt1.currentTime);
//         assert(gt.getColor() == gt1.getColor());
//         assert(gt1.getColor() == "Red");
//         assert(gt.getContent() == gt1.getContent());
//         assert(gt1.getContent() == "Hello");

//         JSONValue parametersInJson;
//         parametersInJson["name"] = "Hunt";
//         string parameterModel = JsonSerializer.getItemAs!(string)(parametersInJson, "name");
//         assert(parameterModel == "Hunt");
//     }   

//     @Test void testGetAsSysTime() {
//         SysTime st1 = Clock.currTime;
//         JSONValue jv = JSONValue(st1.toString());
//         // trace(jv);
//         SysTime st2 = SysTime.fromSimpleString(jv.str);
//         // trace(st2.toString());
//         st2 = JsonSerializer.fromJson!(SysTime)(jv);
//         // trace(st2.toString());
//         assert(st1 == st2);
//     }

//     @Test void testConstParameter() {
//         SysTime st1 = Clock.currStdTime;
//         JSONValue jv;
//         jv["stdtime"] = st1.stdTime;
//         // trace(jv.toString());
//         const(JSONValue)* ptr = "stdtime" in jv;
//         if(ptr !is null) {
//             SysTime st2 = JsonSerializer.fromJson!(SysTime)(*ptr);
//             // trace(st2.toString());
//             assert(st1 == st2);
//         }
//     }

//     void testGetAsBasic02() {
//         // auto json = JSONValue(42);
//         // auto result = fromJson!(Nullable!int)(json);
//         // assert(!result.isNull && result.get() == json.integer);

//         // json = JSONValue(null);
//         // assert(JsonSerializer.fromJson!(Nullable!int)(json).isNull);

//         assert(JsonSerializer.fromJson!JSONValue(JSONValue(42)) == JSONValue(42));
//     }

//     void testGetAsNumeric() {
//         assert(JsonSerializer.fromJson!float(JSONValue(3.0)) == 3.0);
//         assert(JsonSerializer.fromJson!int(JSONValue(42)) == 42);
//         assert(JsonSerializer.fromJson!uint(JSONValue(42U)) == 42U);
//         assert(JsonSerializer.fromJson!char(JSONValue('a')) == 'a');

//         // quirky JSON cases

//         assert(JsonSerializer.fromJson!int(JSONValue(null)) == 0);
//         assert(JsonSerializer.fromJson!int(JSONValue(false)) == 0);
//         assert(JsonSerializer.fromJson!int(JSONValue(true)) == 1);
//         assert(JsonSerializer.fromJson!int(JSONValue("42")) == 42);
//         assert(JsonSerializer.fromJson!char(JSONValue("a")) == 'a');
//     }

//     void testGetAsBool() {
//         assert(JsonSerializer.fromJson!bool(JSONValue(false)) == false);
//         assert(JsonSerializer.fromJson!bool(JSONValue(true)) == true);

//         // quirky JSON cases

//         assert(JsonSerializer.fromJson!bool(JSONValue(null)) == false);
//         assert(JsonSerializer.fromJson!bool(JSONValue(0.0)) == false);
//         assert(JsonSerializer.fromJson!bool(JSONValue(0)) == false);
//         assert(JsonSerializer.fromJson!bool(JSONValue(0U)) == false);
//         assert(JsonSerializer.fromJson!bool(JSONValue("")) == false);

//         assert(JsonSerializer.fromJson!bool(JSONValue(3.0)) == true);
//         assert(JsonSerializer.fromJson!bool(JSONValue(42)) == true);
//         assert(JsonSerializer.fromJson!bool(JSONValue(42U)) == true);
//         assert(JsonSerializer.fromJson!bool(JSONValue("Hello world")) == true);
//         assert(JsonSerializer.fromJson!bool(JSONValue(new int[0])) == true);        
//     }

//     void testGetAsString() {
//         enum Operation : string {
//             create = "create",
//             delete_ = "delete"
//         }

//         assert(JsonSerializer.fromJson!Operation(JSONValue("create")) == Operation.create);
//         assert(JsonSerializer.fromJson!Operation(JSONValue("delete")) == Operation.delete_);

//         auto json = JSONValue("Hello");
//         assert(JsonSerializer.fromJson!string(json) == json.str);
//         assert(JsonSerializer.fromJson!(char[])(json) == json.str);
//         assert(JsonSerializer.fromJson!(wstring)(json) == "Hello"w);
//         assert(JsonSerializer.fromJson!(wchar[])(json) == "Hello"w);
//         assert(JsonSerializer.fromJson!(dstring)(json) == "Hello"d);
//         assert(JsonSerializer.fromJson!(dchar[])(json) == "Hello"d);

//         // beware of the fact that JSONValue treats chars as integers; this returns "97" and not "a"
//         assert(JsonSerializer.fromJson!string(JSONValue('a')) != "a");
//         assert(JsonSerializer.fromJson!string(JSONValue("a")) == "a");

//         enum TestEnum : string {
//             hello = "hello",
//             world = "world"
//         }

//         assert(JsonSerializer.fromJson!TestEnum(JSONValue("hello")) == TestEnum.hello);
//         assert(JsonSerializer.fromJson!TestEnum(JSONValue("world")) == TestEnum.world);

//         // quirky JSON cases

//         assert(JsonSerializer.fromJson!string(JSONValue(null)) == "null");
//         assert(JsonSerializer.fromJson!string(JSONValue(false)) == "false");
//         assert(JsonSerializer.fromJson!string(JSONValue(true)) == "true");
//     }

//     void testGetAsArray() {
//         assert(JsonSerializer.fromJson!(int[])(JSONValue([0, 1, 2, 3])) == [0, 1, 2, 3]);

//         // quirky JSON cases
//         assert(JsonSerializer.fromJson!(byte[], false)(JSONValue([0, 1, 2, 3])) == [0, 1, 2, 3]);
//         assert(JsonSerializer.fromJson!(int[])(JSONValue(null)) == []);
//         assert(JsonSerializer.fromJson!(int[])(JSONValue(false)) == [0]);
//         assert(JsonSerializer.fromJson!(bool[])(JSONValue(true)) == [true]);
//         assert(JsonSerializer.fromJson!(float[])(JSONValue(3.0)) == [3.0]);
//         assert(JsonSerializer.fromJson!(int[])(JSONValue(42)) == [42]);
//         assert(JsonSerializer.fromJson!(uint[])(JSONValue(42U)) == [42U]);
//         assert(JsonSerializer.fromJson!(string[])(JSONValue("Hello")) == ["Hello"]);
//     }

//     /// To Json

//     void testNullableToJson()  {
//         import std.typecons;
//         // assert(JsonSerializer.toJson(Nullable!int()) == Nullable!JSONValue());
//         // assert(JsonSerializer.toJson(Nullable!int(42)) == JSONValue(42));
//     }

//     void testBasicTypeToJson() {
//         assert(JsonSerializer.toJson(3.0) == JSONValue(3.0));
//         assert(JsonSerializer.toJson(42) == JSONValue(42));
//         assert(JsonSerializer.toJson(42U) == JSONValue(42U));
//         assert(JsonSerializer.toJson(false) == JSONValue(false));
//         assert(JsonSerializer.toJson(true) == JSONValue(true));
//         assert(JsonSerializer.toJson('a') == JSONValue('a'));
//         assert(JsonSerializer.toJson("Hello world") == JSONValue("Hello world"));
//         assert(JsonSerializer.toJson(JSONValue(42)) == JSONValue(42));
//     }

//     @Test void testSysTimeToJson() {
//         SysTime st1 = Clock.currTime;
//         JSONValue jv1 = JSONValue(st1.toString());
//         JSONValue jv2 = JsonSerializer.toJson(st1, false);
        
//         assert(jv1 == jv2);
//     }

//     void testArrayToJson() {
//         assert(JsonSerializer.toJson([0, 1, 2]) == JSONValue([0, 1, 2]));
//         assert(JsonSerializer.toJson(["hello", "world"]) == JSONValue(["hello", "world"]));

//         GreetingBase[] greetings;
//         greetings ~= new GreetingBase(1, "Hello");
//         greetings ~= new GreetingBase(2, "World");

//         JSONValue json = JsonSerializer.toJson(greetings);
//         trace(json);
        
//         json = JsonSerializer.toJson!(OnlyPublic.yes, TraverseBase.no)(greetings);
//         trace(json);
//     }


//     void testArrayToJson02() {

//         Greeting[] greetings;
//         greetings ~= new Greeting(1, "Hello");
//         greetings ~= new Greeting(2, "World");

//         greetings[0].setPrivateMember("private member");

//         JSONValue json = JsonSerializer.toJson(greetings);
//         info(json.toPrettyString());
        
//         json = JsonSerializer.toJson!(OnlyPublic.yes, TraverseBase.no)(greetings);
//         info(json.toPrettyString());

//         json = JsonSerializer.toJson!(OnlyPublic.yes, TraverseBase.yes)(greetings);
//         info(json.toPrettyString());

//     }

//     void testAssociativeArrayToJson() {
//         assert(JsonSerializer.toJson(["hello" : 16, "world" : 42]) == JSONValue(["hello" : 16, "world" : 42]));
//         assert(JsonSerializer.toJson(['a' : 16, 'b' : 42]) == JSONValue(["a" : 16, "b" : 42]));
//         assert(JsonSerializer.toJson([0 : 16, 1 : 42]) == JSONValue(["0" : 16, "1" : 42]));
//     }

    // void testJsonSerializable() {

    //     GreetingSettings settings = new GreetingSettings();

    //     JSONValue json_class = JsonSerializer.toJson(settings);
    //     // info(json_class.toPrettyString());
    //     auto itemPtr = MetaTypeName in json_class;
    //     assert(itemPtr is null);

    //     ISettings isettings = settings;
    //     JSONValue json_interface = JsonSerializer.toJson(isettings);
    //     // info(json_interface.toPrettyString());

    //     itemPtr = MetaTypeName in json_interface;
    //     assert(itemPtr !is null);
    // }

    void testDepth() {
        Greeting gt = new Greeting();
        gt.setPrivateMember("private member");
        gt.id = 123;
        gt.content = "Hello, world!";
        gt.creationTime = Clock.currTime;
        gt.currentTime = Clock.currStdTime;
        gt.setColor("Red");
        gt.setContent("Hello");
        gt.addGuest("gest02", 25);

        JSONValue jv;
        const(JSONValue)* itemPtr;

        // depth -1
        jv = JsonSerializer.toJson!(OnlyPublic.no, 
            TraverseBase.yes, IncludeMeta.no)(gt);
        // trace(jv.toPrettyString());

        itemPtr = "guests" in jv;
        assert(itemPtr !is null);

        itemPtr = "settings" in jv;
        assert(itemPtr !is null);

        itemPtr = "times" in jv;
        assert(itemPtr !is null);

        // depth 0
        jv = JsonSerializer.toJson!(OnlyPublic.no, 
            TraverseBase.yes, IncludeMeta.no, 0)(gt);
        // trace(jv.toPrettyString());
        itemPtr = "guests" in jv;
        assert(itemPtr is null);

        itemPtr = "settings" in jv;
        assert(itemPtr is null);

        itemPtr = "times" in jv;
        assert(itemPtr is null);

        // depth 1
        jv = JsonSerializer.toJson!(OnlyPublic.no, 
            TraverseBase.yes, IncludeMeta.no, 1)(gt);
        trace(jv.toPrettyString());

        itemPtr = "guests" in jv;
        assert(itemPtr !is null);

        itemPtr = "settings" in jv;
        assert(itemPtr !is null);

        itemPtr = "times" in jv;
        assert(itemPtr !is null);
    }

    // void testMap() {

    //     JobDataMap m = new JobDataMap();
    //     m.put("name", "Bob");
    //     m.put("age", 23);
    //     trace(m.toString());

    //     // ubyte[] d = cast(ubyte[])m.serialize();
    //     // tracef("%(%02X %)", d);

    //     JSONValue jv = JsonSerializer.toJson(m);
    //     // trace(jv.toPrettyString());

    //     JobDataMap m2 = JsonSerializer.fromJson!(JobDataMap)(jv);
    //     trace(m.toString());
    //     string name = m2.getFromString!(string)("name");
    //     int age = m2.getFromString!(int)("age");
    //     assert(name == "Bob");
    //     assert(age == 23);

    // }    
}



struct GreetingModel
{
    int id;
    string content;
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
