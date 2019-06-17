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
 */
module test.quartz.StringKeyDirtyFlagMap;

import test.quartz.DirtyFlagMap;

import hunt.Exceptions;
import hunt.Boolean;
import hunt.Char;
import hunt.Double;
import hunt.Float;
import hunt.Integer;
import hunt.Long;
import hunt.Number;
import hunt.String;
import hunt.util.Serialize;
import hunt.util.Traits;

/**
 * <p>
 * An implementation of <code>Map</code> that wraps another <code>Map</code>
 * and flags itself 'dirty' when it is modified, enforces that all keys are
 * Strings. 
 * </p>
 * 
 * <p>
 * All allowsTransientData flag related methods are deprecated as of version 1.6.
 * </p>
 */
class StringKeyDirtyFlagMap : DirtyFlagMap!(string, Object) {
    
    /**
     * @deprecated JDBCJobStores no longer prune out data.  If you
     * include non-Serializable values in the Map, you will now get an 
     * exception when attempting to store it in a database.
     */
    private bool allowsTransientData = false;

    this() {
        super();
    }

    this(int initialCapacity) {
        super(initialCapacity);
    }

    this(int initialCapacity, float loadFactor) {
        super(initialCapacity, loadFactor);
    }

    // override
    // bool opEquals(Object o) {
    //     return super== obj;
    // }

    
    /**
     * Get a copy of the Map's string keys in an array of Strings.
     */
    // string[] getKeys() {
    //     return keySet().toArray(new string[size()]);
    // }

    /**
     * Tell the <code>StringKeyDirtyFlagMap</code> that it should
     * allow non-<code>Serializable</code> values.  Enforces that the Map 
     * doesn't already include data.
     * 
     * @deprecated JDBCJobStores no longer prune out data.  If you
     * include non-Serializable values in the Map, you will now get an 
     * exception when attempting to store it in a database.
     */
    // void setAllowsTransientData(bool allowsTransientData) {
    
    //     if (containsTransientData() && !allowsTransientData) {
    //         throw new IllegalStateException(
    //             "Cannot set property 'allowsTransientData' to 'false' "
    //                 ~ "when data map contains non-serializable objects.");
    //     }
    
    //     this.allowsTransientData = allowsTransientData;
    // }

    /**
     * Whether the <code>StringKeyDirtyFlagMap</code> allows 
     * non-<code>Serializable</code> values.
     * 
     * @deprecated JDBCJobStores no longer prune out data.  If you
     * include non-Serializable values in the Map, you will now get an 
     * exception when attempting to store it in a database.
     */
    // bool getAllowsTransientData() {
    //     return allowsTransientData;
    // }

    /**
     * Determine whether any values in this Map do not implement 
     * <code>Serializable</code>.  Always returns false if this Map
     * is flagged to not allow data.
     * 
     * @deprecated JDBCJobStores no longer prune out data.  If you
     * include non-Serializable values in the Map, you will now get an 
     * exception when attempting to store it in a database.
     */
    // bool containsTransientData() {
    //     if (!getAllowsTransientData()) { // short circuit...
    //         return false;
    //     }
    
    //     string[] keys = getKeys();
    //     for (int i = 0; i < keys.length; i++) {
    //         Object o = super.get(keys[i]);
    //         if (!(o instanceof Serializable)) {
    //             return true;
    //         }
    //     }
    
    //     return false;
    // }

    /**
     * Removes any data values in the map that are non-Serializable.  Does 
     * nothing if this Map does not allow data.
     * 
     * @deprecated JDBCJobStores no longer prune out data.  If you
     * include non-Serializable values in the Map, you will now get an 
     * exception when attempting to store it in a database.
     */
    // void removeTransientData() {
    //     if (!getAllowsTransientData()) { // short circuit...
    //         return;
    //     }
    
    //     string[] keys = getKeys();
    //     for (int i = 0; i < keys.length; i++) {
    //         Object o = super.get(keys[i]);
    //         if (!(o instanceof Serializable)) {
    //             remove(keys[i]);
    //         }
    //     }
    // }

    // Due to Generic enforcement, this override method is no longer needed.
//    /**
//     * <p>
//     * Adds the name-value pairs in the given <code>Map</code> to the 
//     * <code>StringKeyDirtyFlagMap</code>.
//     * </p>
//     * 
//     * <p>
//     * All keys must be <code>string</code>s.
//     * </p>
//     */
//    override
//    void putAll(Map!(string, Object) map) {
//        for (Iterator<?> entryIter = map.entrySet().iterator(); entryIter.hasNext();) {
//            Map.Entry<?,?> entry = (Map.Entry<?,?>) entryIter.next();
//            
//            // will throw IllegalArgumentException if key is not a string
//            put(entry.getKey(), entry.getValue());
//        }
//    }

    /**
     * <p>
     * Adds the given <code>int</code> value to the <code>StringKeyDirtyFlagMap</code>.
     * </p>
     */
    void put(string key, int value) {
        super.put(key, Integer.valueOf(value));
    }

    /**
     * <p>
     * Adds the given <code>long</code> value to the <code>StringKeyDirtyFlagMap</code>.
     * </p>
     */
    void put(string key, long value) {
        super.put(key, Long.valueOf(value));
    }

    /**
     * <p>
     * Adds the given <code>float</code> value to the <code>StringKeyDirtyFlagMap</code>.
     * </p>
     */
    void put(string key, float value) {
        super.put(key, Float.valueOf(value));
    }

    /**
     * <p>
     * Adds the given <code>double</code> value to the <code>StringKeyDirtyFlagMap</code>.
     * </p>
     */
    void put(string key, double value) {
        super.put(key, Double.valueOf(value));
    }

    /**
     * <p>
     * Adds the given <code>bool</code> value to the <code>StringKeyDirtyFlagMap</code>.
     * </p>
     */
    void put(string key, bool value) {
        super.put(key, Boolean.valueOf(value));
    }

    /**
     * <p>
     * Adds the given <code>char</code> value to the <code>StringKeyDirtyFlagMap</code>.
     * </p>
     */
    void put(string key, char value) {
        super.put(key, Char.valueOf(value));
    }

    /**
     * <p>
     * Adds the given <code>string</code> value to the <code>StringKeyDirtyFlagMap</code>.
     * </p>
     */
    void put(string key, string value) {
        super.put(key, new String(value));
    }

    /**
     * <p>
     * Adds the given <code>Object</code> value to the <code>StringKeyDirtyFlagMap</code>.
     * </p>
     */
    override
    Object put(string key, Object value) {
        return super.put(key, value);
    }
    
    /**
     * <p>
     * Retrieve the identified <code>int</code> value from the <code>StringKeyDirtyFlagMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not an Integer.
     */
    int getInt(string key) {
        Object obj = get(key);
    
        try {
            Number n = cast(Number) obj;
            if(n !is null)
                return n.intValue();
            return Integer.parseInt(obj.toString());
        } catch (Exception e) {
            throw new ClassCastException("Identified object is not an Integer.");
        }
    }

    /**
     * <p>
     * Retrieve the identified <code>long</code> value from the <code>StringKeyDirtyFlagMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a Long.
     */
    long getLong(string key) {
        Object obj = get(key);
    
        try {
            Number n = cast(Number) obj;
            if(n !is null)
                return n.longValue();
            return Long.parseLong(obj.toString());
        } catch (Exception e) {
            throw new ClassCastException("Identified object is not a Long.");
        }
    }

    /**
     * <p>
     * Retrieve the identified <code>float</code> value from the <code>StringKeyDirtyFlagMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a Float.
     */
    float getFloat(string key) {
        Object obj = get(key);
    
        try {
            Number n = cast(Number) obj;
            if(n !is null)
                return n.floatValue();
            return Float.parseFloat(obj.toString());
        } catch (Exception e) {
            throw new ClassCastException("Identified object is not a Float.");
        }
    }

    /**
     * <p>
     * Retrieve the identified <code>double</code> value from the <code>StringKeyDirtyFlagMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a Double.
     */
    double getDouble(string key) {
        Object obj = get(key);
    
        try {
            Number n = cast(Number) obj;
            if(n !is null)
                return n.doubleValue();
            return Double.parseDouble(obj.toString());
        } catch (Exception e) {
            throw new ClassCastException("Identified object is not a Double.");
        }
    }

    /**
     * <p>
     * Retrieve the identified <code>bool</code> value from the <code>StringKeyDirtyFlagMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a Boolean.
     */
    bool getBoolean(string key) {
        Object obj = get(key);
    
        try {
            Boolean n = cast(Boolean) obj;
            if(n !is null)
                return n.booleanValue();
            return Boolean.parseBoolean(obj.toString());
        } catch (Exception e) {
            throw new ClassCastException("Identified object is not a Boolean.");
        }
    }

    /**
     * <p>
     * Retrieve the identified <code>char</code> value from the <code>StringKeyDirtyFlagMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a Character.
     */
    char getChar(string key) {
        Object obj = get(key);
    
        try {
            Char n = cast(Char) obj;
            if(n !is null)
                return n.charValue();
            return (obj.toString())[0];
        } catch (Exception e) {
            throw new ClassCastException("Identified object is not a Character.");
        }
    }

    /**
     * <p>
     * Retrieve the identified <code>string</code> value from the <code>StringKeyDirtyFlagMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string.
     */
    string getString(string key) {
        Object obj = get(key);

        if(obj is null)
            throw new NullPointerException("key: " ~ key);
    
        try {
            return obj.toString();
        } catch (Exception e) {
            throw new ClassCastException("Identified object is not a string.");
        }
    }

    mixin CloneMemberTemplate!(typeof(this));  
}
