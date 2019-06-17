
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

module test.quartz.JobDataMap;

import hunt.util.Common;

static if(CompilerHelper.isGreaterThan (2086)) {

import hunt.collection.Map;

import test.quartz.StringKeyDirtyFlagMap;

import hunt.Nullable;
import hunt.String;

import std.conv;

/**
 * Holds state information for <code>Job</code> instances.
 * 
 * <p>
 * <code>JobDataMap</code> instances are stored once when the <code>Job</code>
 * is added to a scheduler. They are also re-persisted after every execution of
 * jobs annotated with <code>@PersistJobDataAfterExecution</code>.
 * </p>
 * 
 * <p>
 * <code>JobDataMap</code> instances can also be stored with a 
 * <code>Trigger</code>.  This can be useful in the case where you have a Job
 * that is stored in the scheduler for regular/repeated use by multiple 
 * Triggers, yet with each independent triggering, you want to supply the
 * Job with different data inputs.  
 * </p>
 * 
 * <p>
 * The <code>JobExecutionContext</code> passed to a Job at execution time 
 * also contains a convenience <code>JobDataMap</code> that is the result
 * of merging the contents of the trigger's JobDataMap (if any) over the
 * Job's JobDataMap (if any).  
 * </p>
 *
 * <p>
 * Update since 2.2.4 - We keep an dirty flag for this map so that whenever you modify(add/delete) any of the entries,
 * it will set to "true". However if you create new instance using an exising map with {@link #JobDataMap(Map)}, then
 * the dirty flag will NOT be set to "true" until you modify the instance.
 * </p>
 * 
 * @see Job
 * @see PersistJobDataAfterExecution
 * @see Trigger
 * @see JobExecutionContext
 * 
 * @author James House
 */
class JobDataMap : StringKeyDirtyFlagMap {

    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Create an empty <code>JobDataMap</code>.
     * </p>
     */
    this() {
        super(15);
    }

    this(int initialCapacity) {
        super(initialCapacity);
    }

    /**
     * <p>
     * Create a <code>JobDataMap</code> with the given data.
     * </p>
     */
    this(Map!(string, Object) mapTyped, int initialCapacity = 15) {
        super(initialCapacity);
         // casting to keep API compatible and avoid compiler errors/warnings.
        // Map!(string, Object) mapTyped = (Map!(string, Object))map;
        putAll(mapTyped);

        // When constructing a new data map from another existing map, we should NOT mark dirty flag as true
        // Use case: loading JobDataMap from DB
        clearDirtyFlag();
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    void putAsString(T)(string key, T value) {
        String strValue = new String(to!string(value));

        super.put(key, strValue);
    }

    /**
     * <p>
     * Adds the given <code>bool</code> value as a string version to the
     * <code>Job</code>'s data map.
     * </p>
     */
    // void putAsString(string key, bool value) {
    //     String strValue = new String(to!string(value));

    //     super.put(key, strValue);
    // }

    /**
     * <p>
     * Adds the given <code>Boolean</code> value as a string version to the
     * <code>Job</code>'s data map.
     * </p>
     */
    // void putAsString(string key, Boolean value) {
    //     string strValue = value.toString();

    //     super.put(key, strValue);
    // }

    /**
     * <p>
     * Adds the given <code>char</code> value as a string version to the
     * <code>Job</code>'s data map.
     * </p>
     */
    // void putAsString(string key, char value) {
    //     String strValue = new String(to!string(value));

    //     super.put(key, strValue);
    // }

    /**
     * <p>
     * Adds the given <code>Character</code> value as a string version to the
     * <code>Job</code>'s data map.
     * </p>
     */
    // void putAsString(string key, Character value) {
    //     string strValue = value.toString();

    //     super.put(key, strValue);
    // }

    /**
     * <p>
     * Adds the given <code>double</code> value as a string version to the
     * <code>Job</code>'s data map.
     * </p>
     */
    // void putAsString(string key, double value) {
    //     String strValue = new String(to!string(value));

    //     super.put(key, strValue);
    // }

    /**
     * <p>
     * Adds the given <code>Double</code> value as a string version to the
     * <code>Job</code>'s data map.
     * </p>
     */
    // void putAsString(string key, Double value) {
    //     string strValue = value.toString();

    //     super.put(key, strValue);
    // }

    /**
     * <p>
     * Adds the given <code>float</code> value as a string version to the
     * <code>Job</code>'s data map.
     * </p>
     */
    // void putAsString(string key, float value) {
    //     String strValue = new String(to!string(value));

    //     super.put(key, strValue);
    // }

    /**
     * <p>
     * Adds the given <code>Float</code> value as a string version to the
     * <code>Job</code>'s data map.
     * </p>
     */
    // void putAsString(string key, Float value) {
    //     string strValue = value.toString();

    //     super.put(key, strValue);
    // }

    /**
     * <p>
     * Adds the given <code>int</code> value as a string version to the
     * <code>Job</code>'s data map.
     * </p>
     */
    // void putAsString(string key, int value) {
    //     string strValue = Integer.valueOf(value).toString();

    //     super.put(key, strValue);
    // }

    /**
     * <p>
     * Adds the given <code>Integer</code> value as a string version to the
     * <code>Job</code>'s data map.
     * </p>
     */
    // void putAsString(string key, Integer value) {
    //     string strValue = value.toString();

    //     super.put(key, strValue);
    // }

    /**
     * <p>
     * Adds the given <code>long</code> value as a string version to the
     * <code>Job</code>'s data map.
     * </p>
     */
    // void putAsString(string key, long value) {
    //     string strValue = Long.valueOf(value).toString();

    //     super.put(key, strValue);
    // }

    /**
     * <p>
     * Adds the given <code>Long</code> value as a string version to the
     * <code>Job</code>'s data map.
     * </p>
     */
    // void putAsString(string key, Long value) {
    //     string strValue = value.toString();

    //     super.put(key, strValue);
    // }

    T getFromString(T)(string key) {
        Object obj = get(key);
        string v = obj.toString();
        return to!T(v);
    }


    /**
     * <p>
     * Retrieve the identified <code>int</code> value from the <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string.
     */
    int getIntFromString(string key) {
        // Object obj = get(key);
        // string v = obj.toString();
        // return to!int(v);
        return getFromString!(int)(key);
    }

    /**
     * <p>
     * Retrieve the identified <code>int</code> value from the <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string or Integer.
     */
    int getIntValue(string key) {
        Object obj = get(key);
        String str = cast(String)obj;

        if(str !is null) {
            return getFromString!(int)(key);
        } else {
            return getInt(key);
        }
    }
    
    /**
     * <p>
     * Retrieve the identified <code>int</code> value from the <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string.
     */
    // Integer getIntegerFromString(string key) {
    //     Object obj = get(key);

    //     return new Integer((string) obj);
    // }

    /**
     * <p>
     * Retrieve the identified <code>bool</code> value from the <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string.
     */
    bool getBooleanValueFromString(string key) {
        // Object obj = get(key);

        // return Boolean.valueOf((string) obj);
        return getFromString!(bool)(key);
    }

    /**
     * <p>
     * Retrieve the identified <code>bool</code> value from the 
     * <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string or Boolean.
     */
    bool getBooleanValue(string key) {
        Object obj = get(key);
        String str = cast(String)obj;

        if(str !is null) {
            return getFromString!(bool)(key);
        } else {
            return getBoolean(key);
        }
    }

    /**
     * <p>
     * Retrieve the identified <code>Boolean</code> value from the <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string.
     */
    // Boolean getBooleanFromString(string key) {
    //     Object obj = get(key);

    //     return Boolean.valueOf((string) obj);
    // }

    /**
     * <p>
     * Retrieve the identified <code>char</code> value from the <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string.
     */
    char getCharFromString(string key) {
        return getFromString!(char)(key);
    }

    /**
     * <p>
     * Retrieve the identified <code>Character</code> value from the <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string.
     */
    // Character getCharacterFromString(string key) {
    //     Object obj = get(key);

    //     return ((string) obj)[0];
    // }

    /**
     * <p>
     * Retrieve the identified <code>double</code> value from the <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string.
     */
    double getDoubleValueFromString(string key) {
        return getFromString!(double)(key);
    }

    /**
     * <p>
     * Retrieve the identified <code>double</code> value from the <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string or Double.
     */
    double getDoubleValue(string key) {
        Object obj = get(key);
        String str = cast(String)obj;

        if(str !is null) {
            return getFromString!(double)(key);
        } else {
            return getDouble(key);
        }
    }

    /**
     * <p>
     * Retrieve the identified <code>Double</code> value from the <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string.
     */
    // Double getDoubleFromString(string key) {
    //     Object obj = get(key);

    //     return new Double((string) obj);
    // }

    /**
     * <p>
     * Retrieve the identified <code>float</code> value from the <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string.
     */
    float getFloatValueFromString(string key) {
        return getFromString!(float)(key);
    }

    /**
     * <p>
     * Retrieve the identified <code>float</code> value from the <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string or Float.
     */
    float getFloatValue(string key) {
        Object obj = get(key);
        String str = cast(String)obj;

        if(str !is null) {
            return getFromString!(float)(key);
        } else {
            return getFloat(key);
        }
    }
    
    /**
     * <p>
     * Retrieve the identified <code>Float</code> value from the <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string.
     */
    // Float getFloatFromString(string key) {
    //     Object obj = get(key);

    //     return new Float((string) obj);
    // }

    /**
     * <p>
     * Retrieve the identified <code>long</code> value from the <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string.
     */
    long getLongValueFromString(string key) {
        return getFromString!(long)(key);
    }

    /**
     * <p>
     * Retrieve the identified <code>long</code> value from the <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string or Long.
     */
    long getLongValue(string key) {
        Object obj = get(key);
        String str = cast(String)obj;

        if(str !is null) {
            return getFromString!(long)(key);
        } else {
            return getLong(key);
        }
    }
    
    /**
     * <p>
     * Retrieve the identified <code>Long</code> value from the <code>JobDataMap</code>.
     * </p>
     * 
     * @throws ClassCastException
     *           if the identified object is not a string.
     */
    // Long getLongFromString(string key) {
    //     Object obj = get(key);

    //     return new Long((string) obj);
    // }
}

}