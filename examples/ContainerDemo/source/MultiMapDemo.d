module MultiMapDemo;

import std.stdio;
import std.conv;
import std.range;

import hunt.collection.ArrayList;
import hunt.collection.HashMap;
import hunt.collection.List;
import hunt.collection.Map;
import hunt.collection.MultiMap;

import hunt.util.Assert;
import hunt.text;
import hunt.util.TypeUtils;

// alias assertTrue = Assert.assertTrue;
// alias assertFalse = Assert.assertFalse;
// alias assertThat = Assert.assertThat;
// alias assertEquals = Assert.assertEquals;
// alias assertNull = Assert.assertNull;

class MultiMapDemo {

    void testBasicOperations() {
        MultiMap!string outdoorElements = new MultiMap!string();
        outdoorElements.add("fish", "walleye");
        outdoorElements.add("fish", "muskellunge");
        outdoorElements.add("fish", "bass");
        outdoorElements.add("insect", "ants");
        outdoorElements.add("insect", "water boatman");
        outdoorElements.add("insect", "Lord Howe Island stick insect");
        outdoorElements.add("tree", "oak");
        outdoorElements.add("tree", "birch");

        List!(string) fishies = outdoorElements.getValues("fish");

        writeln("found fishies: ");
        foreach(string name; fishies) {
            writeln("\t", name);
        }

        assert(fishies.size() == 3);
    }

    /**
	 * Tests {@link MultiMap#put(Object, Object)}
	 */
	void testPut() {
		MultiMap!(string) mm = new MultiMap!(string)();

		string key = "formats";

		mm.put(key, "gzip");
		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip");
	}

	/**
	 * Tests {@link MultiMap#put(Object, Object)}
	 */
	void testPut_Null_String() {
		MultiMap!(string) mm = new MultiMap!(string)();

		string key = "formats";
		string val = null;

		mm.put(key, val);
		assertMapSize(mm, 1);
		assertNullValues(mm, key);
	}

	/**
	 * Tests {@link MultiMap#put(Object, Object)}
	 */
	void testPut_Null_List() {
		MultiMap!(string) mm = new MultiMap!(string)();

		string key = "formats";
		List!(string) vals = null;

		mm.put(key, vals);
		assertMapSize(mm, 1);
		assertNullValues(mm, key);
	}

	/**
	 * Tests {@link MultiMap#put(Object, Object)}
	 */
	void testPut_Replace() {
		MultiMap!(string) mm = new MultiMap!(string)();

		string key = "formats";
		List!(string) ret;

		ret = mm.put(key, "gzip");
		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip");
		Assert.assertNull("Should not have replaced anything", ret);
		List!(string) orig = mm.get(key);

		// Now replace it
		ret = mm.put(key, "jar");
		assertMapSize(mm, 1);
		assertValues(mm, key, "jar");
		Assert.assertEquals("Should have replaced original", orig, ret);
	}

	/**
	 * Tests {@link MultiMap#putValues(string, List)}
	 */
	void testPutValues_List() {
		MultiMap!(string) mm = new MultiMap!(string)();

		string key = "formats";

		List!(string) input = new ArrayList!(string)();
		input.add("gzip");
		input.add("jar");
		input.add("pack200");

		mm.putValues(key, input);
		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip", "jar", "pack200");
	}

	void testPutValues_StringArray() {
		MultiMap!(string) mm = new MultiMap!(string)();

		string key = "formats";

		string[] input = ["gzip", "jar", "pack200" ];
		mm.putValues(key, input);
		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip", "jar", "pack200");
	}

	void testPutValues_VarArgs() {
		MultiMap!(string) mm = new MultiMap!(string)();

		string key = "formats";

		mm.putValues(key, "gzip", "jar", "pack200");
		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip", "jar", "pack200");
	}

	/**
	 * Tests {@link MultiMap#add(string, Object)}
	 */
	void testAdd() {
		MultiMap!(string) mm = new MultiMap!(string)();

		string key = "formats";

		// Setup the key
		mm.put(key, "gzip");
		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip");

		// Add to the key
		mm.add(key, "jar");
		mm.add(key, "pack200");

		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip", "jar", "pack200");
	}

	/**
	 * Tests {@link MultiMap#addValues(string, List)}
	 */
	void testAddValues_List() {
		MultiMap!(string) mm = new MultiMap!(string)();

		string key = "formats";

		// Setup the key
		mm.put(key, "gzip");
		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip");

		// Add to the key
		List!(string) extras = new ArrayList!(string)();
		extras.add("jar");
		extras.add("pack200");
		extras.add("zip");
		mm.addValues(key, extras);

		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip", "jar", "pack200", "zip");
	}

	/**
	 * Tests {@link MultiMap#addValues(string, List)}
	 */
	void testAddValues_List_Empty() {
		MultiMap!(string) mm = new MultiMap!(string)();

		string key = "formats";

		// Setup the key
		mm.put(key, "gzip");
		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip");

		// Add to the key
		List!(string) extras = new ArrayList!(string)();
		mm.addValues(key, extras);

		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip");
	}

	/**
	 * Tests {@link MultiMap#addValues(string, Object[])}
	 */
	void testAddValues_StringArray() {
		MultiMap!(string) mm = new MultiMap!(string)();

		string key = "formats";

		// Setup the key
		mm.put(key, "gzip");
		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip");

		// Add to the key
		string[] extras = [ "jar", "pack200", "zip" ];
		mm.addValues(key, extras);

		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip", "jar", "pack200", "zip");
	}

	/**
	 * Tests {@link MultiMap#addValues(string, Object[])}
	 */
	void testAddValues_StringArray_Empty() {
		MultiMap!(string) mm = new MultiMap!(string)();

		string key = "formats";

		// Setup the key
		mm.put(key, "gzip");
		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip");

		// Add to the key
		string[] extras = new string[0];
		mm.addValues(key, extras);

		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip");
	}

	/**
	 * Tests {@link MultiMap#removeValue(string, Object)}
	 */
	void testRemoveValue() {
		MultiMap!(string) mm = new MultiMap!(string)();

		string key = "formats";

		// Setup the key
		mm.putValues(key, "gzip", "jar", "pack200");
		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip", "jar", "pack200");

		// Remove a value
		mm.removeValue(key, "jar");
		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip", "pack200");

	}

	/**
	 * Tests {@link MultiMap#removeValue(string, Object)}
	 */
	void testRemoveValue_InvalidItem() {
		MultiMap!(string) mm = new MultiMap!(string)();

		string key = "formats";

		// Setup the key
		mm.putValues(key, "gzip", "jar", "pack200");
		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip", "jar", "pack200");

		// Remove a value that isn't there
		mm.removeValue(key, "msi");
		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip", "jar", "pack200");
	}

	/**
	 * Tests {@link MultiMap#removeValue(string, Object)}
	 */
	void testRemoveValue_AllItems() {
		MultiMap!(string) mm = new MultiMap!(string)();

		string key = "formats";

		// Setup the key
		mm.putValues(key, "gzip", "jar", "pack200");
		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip", "jar", "pack200");

		// Remove a value
		mm.removeValue(key, "jar");
		assertMapSize(mm, 1);
		assertValues(mm, key, "gzip", "pack200");

		// Remove another value
		mm.removeValue(key, "gzip");
		assertMapSize(mm, 1);
		assertValues(mm, key, "pack200");

		// Remove last value
		mm.removeValue(key, "pack200");
		assertMapSize(mm, 0); // should be empty now
	}

	/**
	 * Tests {@link MultiMap#removeValue(string, Object)}
	 */
	void testRemoveValue_FromEmpty() {
		MultiMap!(string) mm = new MultiMap!(string)();

		string key = "formats";

		// Setup the key
		mm.putValues(key, new string[0]);
		assertMapSize(mm, 1);
		assertEmptyValues(mm, key);

		// Remove a value that isn't in the underlying values
		mm.removeValue(key, "jar");
		assertMapSize(mm, 1);
		assertEmptyValues(mm, key);
	}

	/**
	 * Tests {@link MultiMap#putAll(java.util.Map)}
	 */
	void testPutAll_Map() {
		MultiMap!(string) mm = new MultiMap!(string)();

		assertMapSize(mm, 0); // Shouldn't have anything yet.

		Map!(string, string) input = new HashMap!(string, string)();
		input.put("food", "apple");
		input.put("color", "red");
		input.put("amount", "bushel");

		mm.putAllValues(input);

		assertMapSize(mm, 3);
		assertValues(mm, "food", "apple");
		assertValues(mm, "color", "red");
		assertValues(mm, "amount", "bushel");
	}

	/**
	 * Tests {@link MultiMap#putAll(java.util.Map)}
	 */
	void testPutAll_MultiMap_Simple() {
		MultiMap!(string) mm = new MultiMap!(string)();

		assertMapSize(mm, 0); // Shouldn't have anything yet.

		MultiMap!(string) input = new MultiMap!(string)();
		input.put("food", "apple");
		input.put("color", "red");
		input.put("amount", "bushel");

		mm.putAll(input);

		assertMapSize(mm, 3);
		assertValues(mm, "food", "apple");
		assertValues(mm, "color", "red");
		assertValues(mm, "amount", "bushel");
	}

	/**
	 * Tests {@link MultiMap#putAll(java.util.Map)}
	 */
	void testPutAll_MultiMapComplex() {
		MultiMap!(string) mm = new MultiMap!(string)();

		assertMapSize(mm, 0); // Shouldn't have anything yet.

		MultiMap!(string) input = new MultiMap!(string)();
		input.putValues("food", "apple", "cherry", "raspberry");
		input.put("color", "red");
		input.putValues("amount", "bushel", "pint");

		mm.putAll(input);

		assertMapSize(mm, 3);
		assertValues(mm, "food", "apple", "cherry", "raspberry");
		assertValues(mm, "color", "red");
		assertValues(mm, "amount", "bushel", "pint");
	}

	/**
	 * Tests {@link MultiMap#toStringArrayMap()}
	 */
	// void testToStringArrayMap() {
	// 	MultiMap!(string) mm = new MultiMap!(string)();
	// 	mm.putValues("food", "apple", "cherry", "raspberry");
	// 	mm.put("color", "red");
	// 	mm.putValues("amount", "bushel", "pint");

	// 	assertMapSize(mm, 3);

	// 	Map!(string, string[]) sam = mm.toStringArrayMap();
	// 	Assert.assertEquals("string Array Map.size", 3, sam.size());

	// 	assertArray("toStringArrayMap(food)", sam.get("food"), "apple", "cherry", "raspberry");
	// 	assertArray("toStringArrayMap(color)", sam.get("color"), "red");
	// 	assertArray("toStringArrayMap(amount)", sam.get("amount"), "bushel", "pint");
	// }

	/**
	 * Tests {@link MultiMap#toString()}
	 */
	void testToString() {
		MultiMap!(string) mm = new MultiMap!(string)();
		mm.put("color", "red");

		Assert.assertEquals("{color=red}", mm.toString());

		mm.putValues("food", "apple", "cherry", "raspberry");

		// Assert.assertEquals("{color=red, food=[apple, cherry, raspberry]}", mm.toString());
        Assert.assertEquals("{food=[apple, cherry, raspberry], color=red}", mm.toString());
	}

	/**
	 * Tests {@link MultiMap#clear()}
	 */
	void testClear() {
		MultiMap!(string) mm = new MultiMap!(string)();
		mm.putValues("food", "apple", "cherry", "raspberry");
		mm.put("color", "red");
		mm.putValues("amount", "bushel", "pint");

		assertMapSize(mm, 3);

		mm.clear();

		assertMapSize(mm, 0);
	}

	/**
	 * Tests {@link MultiMap#containsKey(Object)}
	 */
	void testContainsKey() {
		MultiMap!(string) mm = new MultiMap!(string)();
		mm.putValues("food", "apple", "cherry", "raspberry");
		mm.put("color", "red");
		mm.putValues("amount", "bushel", "pint");

		Assert.assertTrue("Contains Key [color]", mm.containsKey("color"));
		Assert.assertFalse("Contains Key [nutrition]", mm.containsKey("nutrition"));
	}

	/**
	 * Tests {@link MultiMap#containsSimpleValue(Object)}
	 */
	void testContainsSimpleValue() {
		MultiMap!(string) mm = new MultiMap!(string)();
		mm.putValues("food", "apple", "cherry", "raspberry");
		mm.put("color", "red");
		mm.putValues("amount", "bushel", "pint");

		Assert.assertTrue("Contains Value [red]", mm.containsSimpleValue("red"));
        // TODO: Tasks pending completion -@zxp at 9/20/2018, 4:30:01 PM
        // 
		// Assert.assertFalse("Contains Value [nutrition]", mm.containsValue("nutrition"));
	}

	/**
	 * Tests {@link MultiMap#containsValue(Object)}
	 */
	void testContainsValue() {
		MultiMap!(string) mm = new MultiMap!(string)();
		mm.putValues("food", "apple", "cherry", "raspberry");
		mm.put("color", "red");
		mm.putValues("amount", "bushel", "pint");

		List!(string) acr = new ArrayList!(string)();
		acr.add("apple");
		acr.add("cherry");
		acr.add("raspberry");
		Assert.assertTrue("Contains Value [apple,cherry,raspberry]", mm.containsValue(acr));
        // TODO: Tasks pending completion -@zxp at 9/20/2018, 4:31:24 PM
        // 
		// Assert.assertFalse("Contains Value [nutrition]", mm.containsValue("nutrition"));
	}

	/**
	 * Tests {@link MultiMap#containsValue(Object)}
	 */
	// void testContainsValue_LazyList() {
	// 	MultiMap!(string) mm = new MultiMap!(string)();
	// 	mm.putValues("food", "apple", "cherry", "raspberry");
	// 	mm.put("color", "red");
	// 	mm.putValues("amount", "bushel", "pint");

	// 	Object list = LazyList.add(null, "bushel");
	// 	list = LazyList.add(list, "pint");

	// 	Assert.assertTrue("Contains Value [" ~ list ~ "]", mm.containsValue(list));
	// }

	private void assertArray(T)(string prefix, Object[] actualValues, T[] expectedValues... ) {
		Assert.assertEquals(prefix ~ ".size", expectedValues.length, actualValues.length);
		int len = cast(int)actualValues.length;
		for (int i = 0; i < len; i++) {
			Assert.assertEquals(prefix ~ "[" ~ i ~ "]", expectedValues[i], actualValues[i]);
		}
	}

	private void assertValues(T)(MultiMap!(string) mm, string key, T[] expectedValues... ) {
		List!(string) values = mm.getValues(key);

		string prefix = "MultiMap.getValues(" ~ key ~ ")";

		Assert.assertEquals(prefix ~ ".size", expectedValues.length, values.size());
		int len = cast(int)expectedValues.length;
		for (int i = 0; i < len; i++) {
            static if(is(T == class)) {
                if (expectedValues[i] is null) {
                    Assert.assertThat(prefix ~ "[" ~ i.to!string() ~ "]", values.get(i), null);
                } else {
                    Assert.assertEquals(prefix ~ "[" ~ i.to!string() ~ "]", expectedValues[i], values.get(i));
                }
            } else {
                static assert(false, "unsupported type: " ~ T.stringOf);
            }
		}
	}

	private void assertValues(MultiMap!(string) mm, string key, string[] expectedValues... ) {
		List!(string) values = mm.getValues(key);

		string prefix = "MultiMap.getValues(" ~ key ~ ")";

		Assert.assertEquals(prefix ~ ".size", expectedValues.length, values.size());
		int len = cast(int)expectedValues.length;
		for (int i = 0; i < len; i++) {
            if (expectedValues[i] is null) {
                Assert.assertThat(prefix ~ "[" ~ i.to!string() ~ "]", values.get(i), null);
            } else {
                Assert.assertEquals(prefix ~ "[" ~ i.to!string() ~ "]", expectedValues[i], values.get(i));
            } 
		}
	}

	private void assertNullValues(MultiMap!(string) mm, string key) {
		List!(string) values = mm.getValues(key);

		string prefix = "MultiMap.getValues(" ~ key ~ ")";

		Assert.assertThat(prefix ~ ".size", values, null);
	}

	private void assertEmptyValues(MultiMap!(string) mm, string key) {
		List!(string) values = mm.getValues(key);

		string prefix = "MultiMap.getValues(" ~ key ~ ")";

		Assert.assertEquals(prefix ~ ".size", 0, LazyList.size(values));
	}

	private void assertMapSize(MultiMap!(string) mm, int expectedSize) {
		Assert.assertEquals("MultiMap.size", expectedSize, mm.size());
	}

}
