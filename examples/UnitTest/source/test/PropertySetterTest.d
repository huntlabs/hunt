module test.PropertySetterTest;

import hunt.util.Traits;

struct Foo {
	string name = "dog";
	int bar = 42;
	int baz = 31337;

	void setBar(int value) {
		// writefln("setting: value=%d", value);
		bar = value;
	}

	void setBar(string name, int value) {
		// writefln("setting: name=%s, value=%d", name, value);
        this.name = name;
        this.bar = value;
	}

	int getBar() {
		return bar;
	}
}

void testPropertySetter() {
	Foo foo;

	setProperty(foo, "bar", 12);
	assert(foo.bar == 12);
	setProperty(foo, "bar", "112");
	assert(foo.bar == 112);

	setProperty(foo, "bar", "age", 16);
	assert(foo.name == "age");
	assert(foo.bar == 16);
	setProperty(foo, "bar", "age", "36");
	assert(foo.name == "age");
	assert(foo.bar == 36);
}