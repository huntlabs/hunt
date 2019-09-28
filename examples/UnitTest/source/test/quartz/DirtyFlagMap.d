/*
 * All content copyright Terracotta, Inc., unless otherwise indicated. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy
 * of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 *
 */

module test.quartz.DirtyFlagMap;

import hunt.util.Common;

static if(CompilerHelper.isGreaterThan (2086)) {

import hunt.collection.AbstractMap;
import hunt.collection.ArrayList;
import hunt.collection.AbstractCollection;
import hunt.collection.Collection;
import hunt.collection.HashMap;
import hunt.collection.Iterator;
import hunt.collection.Map;
import hunt.collection.Set;

import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.Object;
import hunt.util.Common;
import hunt.util.ObjectUtils;
import hunt.util.Serialize;

import hunt.serialization.Common;
import hunt.serialization.JsonSerializer;

import std.algorithm;
import std.array;
import std.range;

/**
 * <p>
 * An implementation of <code>Map</code> that wraps another <code>Map</code>
 * and flags itself 'dirty' when it is modified.
 * </p>
 *
 * @author James House
 */
class DirtyFlagMap(K, V) : Map!(K, V), Cloneable, JsonSerializable {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Data members.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private bool dirty = false;
    protected Map!(K, V) map;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Constructors.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Create a DirtyFlagMap that 'wraps' a <code>HashMap</code>.
     * </p>
     *
     * @see java.util.HashMap
     */
    this() {
        map = new HashMap!(K, V)();
    }

    /**
     * <p>
     * Create a DirtyFlagMap that 'wraps' a <code>HashMap</code> that has the
     * given initial capacity.
     * </p>
     *
     * @see java.util.HashMap
     */
    this(int initialCapacity) {
        map = new HashMap!(K, V)(initialCapacity);
    }

    /**
     * <p>
     * Create a DirtyFlagMap that 'wraps' a <code>HashMap</code> that has the
     * given initial capacity and load factor.
     * </p>
     *
     * @see java.util.HashMap
     */
    this(int initialCapacity, float loadFactor) {
        map = new HashMap!(K, V)(initialCapacity, loadFactor);
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Interface.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Clear the 'dirty' flag (set dirty flag to <code>false</code>).
     * </p>
     */
    void clearDirtyFlag() {
        dirty = false;
    }

    /**
     * <p>
     * Determine whether the <code>Map</code> is flagged dirty.
     * </p>
     */
    bool isDirty() {
        return dirty;
    }

    /**
     * <p>
     * Get a direct handle to the underlying Map.
     * </p>
     */
    Map!(K, V) getWrappedMap() {
        return map;
    }

    override void clear() {
        if (!map.isEmpty()) {
            dirty = true;
        }
        map.clear();
    }

    override bool containsKey(K key) {
        return map.containsKey(key);
    }

    override bool containsValue(V val) {
        return map.containsValue(val);
    }
    
    override int opApply(scope int delegate(ref K, ref V) dg) {
        return map.opApply(dg);
    }

    override int opApply(scope int delegate(MapEntry!(K, V) entry) dg) {
        return map.opApply(dg);
    }

    override InputRange!K byKey() {
        return map.byKey();
    }

    override InputRange!V byValue() {
        return map.byValue();
    }

    bool opEquals(IObject o) {
        return opEquals(cast(Object) o);
    }

    override
    bool opEquals(Object o) {
        if (o is null) {
            return false;
        }
        DirtyFlagMap dfMap = cast(DirtyFlagMap)o;
        if(dfMap is null)
            return false;

        return map == dfMap.getWrappedMap();
    }

    override size_t toHash() @trusted nothrow {
        return map.toHash();
    }

    override V get(K key) {
        return map.get(key);
    }

    override bool isEmpty() {
        return map.isEmpty();
    }


    override V put(K key, V val) {
        dirty = true;

        return map.put(key, val);
    }

    override void putAll(Map!(K, V) t) {
        if (!t.isEmpty()) {
            dirty = true;
        }

        map.putAll(t);
    }

    override V remove(K key) {
        V obj = map.remove(key);

        if (obj !is null) {
            dirty = true;
        }

        return obj;
    }

    override int size() {
        return map.size();
    }

    override V[] values() {
        return map.values();
    }


    V opIndex(K key) {
        return map.opIndex(key);
    }


    V putIfAbsent(K key, V value) {
        return map.putIfAbsent(key, value);
    }

    bool remove(K key, V value) {
        return map.remove(key, value);
    }
    
    V replace(K key, V value) {
        return map.replace(key, value);
    }

    bool replace(K key, V oldValue, V newValue) {
        return map.replace(key, oldValue, newValue);
    }

    override string toString() {
        return map.toString();
    }

    mixin CloneMemberTemplate!(typeof(this), TopLevel.no, (typeof(this) from, typeof(this) to) {
        HashMap!(K,V) hashMap = cast(HashMap!(K,V))from.map;
        if (hashMap !is null) {
            to.map = cast(Map!(K,V))(hashMap.clone());
        }
    }); 

    // mixin SerializationMember!(typeof(this));

    JSONValue jsonSerialize() {
        JSONValue r = JsonSerializer.serializeObject!(OnlyPublic.no,
        TraverseBase.no, IncludeMeta.no)(this);
        // string[] keys = map.byKey.array;
        
        // static if(is(V == class)) {
        //     string[] values = map.byValue.map!(a => a.toString()).array;
        // } else {
        //     V[] values = map.byValue.array;
        // }

        JSONValue mapJson;
        // // mapJson["type"] = typeid(cast(Object)map).name;
        // // mapJson["keyType"] = K.stringof;
        // // mapJson["valueType"] = V.stringof;
        // mapJson["keys"] = JSONValue(keys);
        // mapJson["values"] = JSONValue(values);

        foreach(K key, V value; map) {
            mapJson[key] = value.toString();
        }

        r["map"] = mapJson;
        trace(r.toPrettyString());
        return r;
    }

    void jsonDeserialize(const(JSONValue) value) {
        import hunt.String;

        trace(value.toPrettyString());
        JsonSerializer.deserializeObject!(typeof(this), TraverseBase.no)(this, value);
        JSONValue mapJson = value["map"];

        // const(JSONValue)[] keys = mapJson["keys"].array;
        // const(JSONValue)[] values = mapJson["values"].array;
        // for(size_t i=0; i< keys.length; i++) {
        //     map.put(keys[i].str, new String(values[i].str));
        // }
        foreach(string key, ref JSONValue value; mapJson) {
            map.put(key, new String(value.str));
        }
    }   
}

}