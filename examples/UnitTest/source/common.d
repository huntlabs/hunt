module common;


import hunt.serialization.Common;
import hunt.serialization.JsonSerializer;
import hunt.logging.ConsoleLogger;
import hunt.util.Common;
import hunt.util.Traits;

import std.conv;
import std.format;
import std.json;
import std.traits;
import std.stdio;
import std.datetime;

class FruitBase : Cloneable {
    string description;

    this() {
        description = "It's the base";
    }

    mixin CloneMemberTemplate!(typeof(this), (typeof(this) from, typeof(this) to) {
        writeln("Checking description. The value is: " ~ from.description);
    });
}

class Fruit : FruitBase {

    private string name;
    private float price;

    this() {
        name = "unnamed";
        price = 0;
    }

    this(string name, float price) {
        this.name = name;
        this.price = price;
    }

    string getName() {
        return name;
    }

    void setName(string name) {
        this.name = name;
    }

    float getPrice() nothrow {
        return price;
    }

    void setPrice(float price) {
        this.price = price;
    }

    // mixin CloneMemberTemplate!(typeof(this));

    mixin CloneMemberTemplate!(typeof(this), (typeof(this) from, typeof(this) to) {
        writefln("Checking description. The last value is: %s", to.description);
        to.description = "description: " ~ from.description;
    });

    override size_t toHash() @trusted nothrow {
        size_t hashcode = 0;
        hashcode = cast(size_t)price * 20;
        hashcode += hashOf(name);
        return hashcode;
    }

    override bool opEquals(Object obj) {
        Fruit pp = cast(Fruit) obj;
        if (pp is null)
            return false;
        return (pp.name == this.name && pp.price == this.price);
    }

    override string toString() {
        return "name: " ~ name ~ "  price: " ~ price.to!string();
    }
}


void testClone() {
	Fruit f1 = new Fruit("Apple", 9.5f);
	f1.description = "normal apple";

	Fruit f2 = f1.clone();
	writeln("Cloned fruit: ", f2.toString());

	assert(f1.getName() == f2.getName());
	assert(f1.getPrice() == f2.getPrice());
    // writeln("f1.description: ", f1.description);
    // writeln("f2.description: ", f2.description);
	assert("description: " ~ f1.description == f2.description);
	
	f1.setName("Peach");

	assert(f1.getName() != f2.getName());
}

void testGetFieldValues() {

    import hunt.util.Traits;
	Fruit f1 = new Fruit("Apple", 9.5f);
	f1.description = "normal apple";

static if (CompilerHelper.isGreaterThan(2086)) {
	trace(f1.getAllFieldValues());
}
}



interface ISettings : JsonSerializable {
    string color();
    void color(string c);
}

class GreetingSettings : ISettings {
    string _color;

    this() {
        _color = "black";
    }

    string color() {
        return _color;
    }

    void color(string c) {
        this._color = c;
    }


    JSONValue jsonSerialize() {
        return JsonSerializer.serializeObject(this);
        // JSONValue v;
        // v["_color"] = _color;
        // return v;
    }
    
    void jsonDeserialize(const(JSONValue) value) {
        info(value.toString());
        _color = value["_color"].str;
    }

}

class GreetingBase {
    int id;
    private string content;

    this() {

    }

    this(int id, string content) {
        this.id = id;
        this.content = content;
    }

    void setContent(string content) {
        this.content = content;
    }

    string getContent() {
        return this.content;
    }

    override string toString() {
        return "id=" ~ to!string(id) ~ ", content=" ~ content;
    }
}

class Greeting : GreetingBase {
    private string privateMember;
    private ISettings settings;
    Object.Monitor skippedMember;

    alias TestHandler = void delegate(string); 

    // FIXME: Needing refactor or cleanup -@zxp at 6/16/2019, 12:33:02 PM
    // 
    string content; // test for the same fieldname

    SysTime creationTime;
    
    @Exclude
    long currentTime;
    
    byte[] bytes;
    string[] members;

    this() {
        super();
        settings = new GreetingSettings();
    }

    this(int id, string content) {
        super(id, content);
        this.content = ">>> " ~ content ~ " <<<";
        settings = new GreetingSettings();
    }

    void setColor(string color) {
        settings.color = color;
    }

    string getColor() {
        return settings.color();
    }

    void voidReturnMethod() {

    }

    void setPrivateMember(string value) {
        this.privateMember = value;
    }

    string getPrivateMember() {
        return this.privateMember;
    }

    override string toString() {
        string s = format("content=%s, creationTime=%s, currentTime=%s",
                content, creationTime, currentTime);
        return s;
    }
}
