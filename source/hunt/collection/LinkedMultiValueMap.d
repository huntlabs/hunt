/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.collection.LinkedMultiValueMap;

import hunt.collection.Collection;
import hunt.collection.LinkedHashMap;
import hunt.collection.LinkedList;
import hunt.collection.List;
import hunt.collection.MultiValueMap;
import hunt.collection.Map;
import hunt.collection.Set;
import hunt.Object;
import hunt.util.ObjectUtils;

import std.range;

/**
 * Simple implementation of {@link MultiValueMap} that wraps a {@link LinkedHashMap},
 * storing multiple values in a {@link LinkedList}.
 *
 * <p>This Map implementation is generally not thread-safe. It is primarily designed
 * for data structures exposed from request objects, for use in a single thread only.
 *
 * @author Arjen Poutsma
 * @author Juergen Hoeller
 */
class LinkedMultiValueMap(K, V) : MultiValueMap!(K, V) {

	private Map!(K, List!(V)) targetMap;


	/**
	 * Create a new LinkedMultiValueMap that wraps a {@link LinkedHashMap}.
	 */
	this() {
		this.targetMap = new LinkedHashMap!(K, List!(V))();
	}

	/**
	 * Create a new LinkedMultiValueMap that wraps a {@link LinkedHashMap}
	 * with the given initial capacity.
	 * @param initialCapacity the initial capacity
	 */
	this(int initialCapacity) {
		this.targetMap = new LinkedHashMap!(K, List!(V))(initialCapacity);
	}

	/**
	 * Copy constructor: Create a new LinkedMultiValueMap with the same mappings as
	 * the specified Map. Note that this will be a shallow copy; its value-holding
	 * List entries will get reused and therefore cannot get modified independently.
	 * @param otherMap the Map whose mappings are to be placed in this Map
	 * @see #clone()
	 * @see #deepCopy()
	 */
	this(Map!(K, List!(V)) otherMap) {
		this.targetMap = new LinkedHashMap!(K, List!(V))(otherMap);
	}


	// MultiValueMap implementation

	override
	V getFirst(K key) {
		List!(V) values = this.targetMap.get(key);
		return (values !is null ? values.get(0) : null);
	}

	override
	void add(K key, V value) {
		List!(V) values = this.targetMap.computeIfAbsent(key, k => new LinkedList!(V)());
		values.add(value);
	}

	override
	void addAll(K key, List!(V) values) {
		List!(V) currentValues = this.targetMap.computeIfAbsent(key, k => new LinkedList!(V)());
		currentValues.addAll(values);
	}

	void addAll(Map!(K, List!V) values) {
		foreach (K key, List!V value ; values) {
			addAll(key, value);
		}
	}

	override
	void set(K key, V value) {
		List!(V) values = new LinkedList!(V)();
		values.add(value);
		this.targetMap.put(key, values);
	}

	override
	void setAll(Map!(K, V) values) {
        foreach (K key, V value ; values) 
            this.set(key, value);
	}

	override
	Map!(K, V) toSingleValueMap() {
		LinkedHashMap!(K, V) singleValueMap = new LinkedHashMap!(K, V)(this.targetMap.size());
        foreach (K key, List!(V) value ; this.targetMap)
            singleValueMap.put(key, value.get(0));
		
		return singleValueMap;
	}


	// Map implementation

	override
	int size() {
		return this.targetMap.size();
	}

	override
	bool isEmpty() {
		return this.targetMap.isEmpty();
	}

	override
	bool containsKey(K key) {
		return this.targetMap.containsKey(key);
	}

	override
	bool containsValue(List!(V) value) {
		return this.targetMap.containsValue(value);
	}

    List!(V) opIndex(K key) {
        return get(key);
    }

	override	
	List!(V) get(K key) {
		return this.targetMap.get(key);
	}

	override
	List!(V) put(K key, List!(V) value) {
		return this.targetMap.put(key, value);
	}
	
    List!(V) putIfAbsent(K key, List!(V) value) {
        List!(V) v;

        if(!containsKey(key))
            v = put(key, value);

        return v;
    }

	override
	List!(V) remove(K key) {
		return this.targetMap.remove(key);
	}
	
    bool remove(K key, List!(V) value){
        List!(V) curValue = get(key);
        if(curValue != value || !containsKey(key))
            return false;
        remove(key);
        return true;
    }

	override
	void putAll(Map!(K, List!(V)) map) {
		this.targetMap.putAll(map);
	}

	override
	void clear() {
		this.targetMap.clear();
	}
	
    bool replace(K key, List!(V) oldValue, List!(V) newValue) {
        List!(V) curValue = get(key);
         if(curValue != oldValue || !containsKey(key)){
            return false;
        }
        put(key, newValue);
        return true;
    }

    List!(V) replace(K key, List!(V) value) {
        List!(V) curValue;
        if (containsKey(key)) {
            curValue = put(key, value);
        }
        return curValue;
    }

    int opApply(scope int delegate(ref K, ref List!(V)) dg)  {
        return this.targetMap.opApply(dg);
    }
    
    int opApply(scope int delegate(MapEntry!(K, List!(V)) entry) dg) {
        return this.targetMap.opApply(dg);
    }
    
    InputRange!K byKey() {
        return this.targetMap.byKey();
    }

    InputRange!(List!(V)) byValue() {
        return this.targetMap.byValue();
    }

	// override
	// Set!(K) keySet() {
	// 	return this.targetMap.keySet();
	// }

	// override
	List!(V)[] values() {
		return this.targetMap.values();
	}

	// override
	// Set<Entry!(K, List!(V))> entrySet() {
	// 	return this.targetMap.entrySet();
	// }


	/**
	 * Create a deep copy of this Map.
	 * @return a copy of this Map, including a copy of each value-holding List entry
	 * @since 4.2
	 * @see #clone()
	 */
	LinkedMultiValueMap!(K, V) deepCopy() {
		LinkedMultiValueMap!(K, V) copy = new LinkedMultiValueMap!(K, V)(this.targetMap.size());
		foreach(K key, List!(V) value; this.targetMap) {
			copy.put(key, new LinkedList!(V)(value));
		}
		return copy;
	}

	/**
	 * Create a regular copy of this Map.
	 * @return a shallow copy of this Map, reusing this Map's value-holding List entries
	 * @since 4.2
	 * @see LinkedMultiValueMap#LinkedMultiValueMap(Map)
	 * @see #deepCopy()
	 */

    mixin CloneMemberTemplate!(typeof(this));	

    bool opEquals(IObject o) {
        return opEquals(cast(Object)o);
    }

	override bool opEquals(Object obj) {
		return this.targetMap == obj;
	}

	override size_t toHash() @trusted nothrow {
		return this.targetMap.toHash;
	}

	override string toString() {
		return this.targetMap.toString();
	}

}
