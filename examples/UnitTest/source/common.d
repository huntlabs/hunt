module common;

import hunt.util.Traits;

import std.conv;
import std.traits;
import std.stdio;

class FruitBase {
    string description;

    this() {

    }

    Object clone() {
        FruitBase copy = cast(FruitBase)typeid(this).create();
        enum string s = generateObjectClone!(FruitBase, this.stringof, copy.stringof);
        mixin(s);
        return copy;
    }
}

class Fruit : FruitBase {

    private string name;
    private float price;

    protected this() {
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

    override Fruit clone() {
        Fruit f = cast(Fruit)super.clone();
        assert(f !is null);
        enum string s = generateObjectClone!(Fruit, this.stringof, f.stringof);
        mixin(s);
        return f;
    }

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


unittest {
	Fruit f1 = new Fruit("Apple", 9.5f);
	f1.description = "normal apple";

	Fruit f2 = f1.clone();
	writeln(f2.toString());
	assert(f1.getName() == f2.getName());
	assert(f1.getPrice() == f2.getPrice());
	assert(f1.description == f2.description);
	
	f1.setName("Peach");

	assert(f1.getName() != f2.getName());
}