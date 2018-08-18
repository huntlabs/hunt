module common;

import std.conv;

class Price
{

    private string item;
    private int price;

    this(string itm, int pr)
    {
        this.item = itm;
        this.price = pr;
    }

    string getItem()
    {
        return item;
    }

    void setItem(string item)
    {
        this.item = item;
    }

    int getPrice()
    {
        return price;
    }

    void setPrice(int price)
    {
        this.price = price;
    }

    override size_t toHash() @trusted nothrow
    {
        size_t hashcode = 0;
        hashcode = price * 20;
        hashcode += hashOf(item);
        return hashcode;
    }

    override bool opEquals(Object obj)
    {
        Price pp = cast(Price) obj;
        if (pp is null)
            return false;
        return (pp.item == this.item && pp.price == this.price);
    }

    override string toString()
    {
        return "item: " ~ item ~ "  price: " ~ price.to!string();
    }
}