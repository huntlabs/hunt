module test.PropertySetterTest;

import hunt.util.Traits;
import hunt.logging.ConsoleLogger;

struct Foo {
	string name = "dog";
	int bar = 42;
	int baz = 31337;

	void setBar(int value) {
		tracef("setting: value=%d", value);
		bar = value;
	}

	void setBar(string name, int value) {
		tracef("setting: name=%s, value=%d", name, value);
        this.name = name;
        this.bar = value;
	}

	int getBar() {
		return bar;
	}
}


interface IFoo {
	void setBaseBar(int value);
}

abstract class FooBase : IFoo {
	abstract void setBaseBar(int value);
}


class FooClass : FooBase {
	string name = "dog";
	int bar = 42;
	int baz = 31337;

	override void setBaseBar(int value) {
		tracef("setting: value=%d", value);
		bar = value;
	}

	void setBar(int value) {
		tracef("setting: value=%d", value);
		bar = value;
	}

	void setBar(string name, int value) {
		tracef("setting: name=%s, value=%d", name, value);
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


	bool r;

	FooClass fooClass = new FooClass();
	setProperty(fooClass, "bar", "age", "26");
	assert(fooClass.bar == 26);

	FooBase fooBase = fooClass;
	r = setProperty(fooBase, "bar", "age", "36");
	assert(!r);
	assert(fooClass.bar == 26);

	FooClass fooBase2 = cast(FooClass) fooBase;
	setProperty(fooBase2, "bar", "age", "16");
	assert(fooClass.bar == 16);

	IFoo foolInterface = fooClass;
	r = foolInterface.setProperty("BaseBar", "age", "46");
	assert(!r);
	assert(fooClass.bar == 16);

	r = foolInterface.setProperty("BaseBar", "46");
	assert(r);
	assert(fooClass.bar == 46);
}