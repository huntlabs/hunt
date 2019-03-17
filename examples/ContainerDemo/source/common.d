module common;

import std.conv;
import std.format;
import hunt.util.Comparator;


class Price {

    private string item;
    private int price;

    this(string itm, int pr) {
        this.item = itm;
        this.price = pr;
    }

    string getItem() {
        return item;
    }

    void setItem(string item) {
        this.item = item;
    }

    int getPrice() nothrow {
        return price;
    }

    void setPrice(int price) {
        this.price = price;
    }

    override size_t toHash() @trusted nothrow {
        size_t hashcode = 0;
        hashcode = price * 20;
        hashcode += hashOf(item);
        return hashcode;
    }

    override bool opEquals(Object obj) {
        Price pp = cast(Price) obj;
        if (pp is null)
            return false;
        return (pp.item == this.item && pp.price == this.price);
    }

    override string toString() {
        return "item: " ~ item ~ "  price: " ~ price.to!string();
    }
}


class Person : Comparable!Person {

    string name;
    int age;

    this(string n, int a) {
        name = n;
        age = a;
    }

    override string toString() {
        return format("Name is %s, Age is %d", name, age);
    }

    int opCmp(Person o) {
        int nameComp = compare(this.name, o.name);
        return (nameComp != 0 ? nameComp : compare(this.age, o.age));
    }

    alias opCmp = Object.opCmp;

}

class ComparatorByPrice : Comparator!Price{

     int compare(Price v1, Price v2) nothrow {
        return .compare(v1.getPrice, v2.getPrice);
    }

}