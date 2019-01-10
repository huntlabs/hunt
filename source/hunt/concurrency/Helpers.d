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

module hunt.concurrency.Helpers;

import hunt.collection.Collection;

/** Shared implementation code for hunt.concurrency. */
class Helpers {
    private this() {}                // non-instantiable

    /**
     * An implementation of Collection.toString() suitable for classes
     * with locks.  Instead of holding a lock for the entire duration of
     * toString(), or acquiring a lock for each call to Iterator.next(),
     * we hold the lock only during the call to toArray() (less
     * disruptive to other threads accessing the collection) and follows
     * the maxim "Never call foreign code while holding a lock".
     */
    static string collectionToString(T)(Collection!T c) {
        T[] a = c.toArray();
        size_t size = a.length;
        if (size == 0)
            return "[]";
        string[] arr = new string[size];
        size_t charLength = 0;

        // Replace every array element with its string representation
        for (size_t i = 0; i < size; i++) {
            T e = a[i];
            // Extreme compatibility with AbstractCollection.toString()
            string s = (typeid(e) == typeid(c)) ? "(this Collection)" : objectToString(e);
            arr[i] = s;
            charLength += s.length;
        }

        return toString(arr, size, charLength);
    }

    /**
     * Like Arrays.toString(), but caller guarantees that size > 0,
     * each element with index 0 <= i < size is a non-null string,
     * and charLength is the sum of the lengths of the input Strings.
     */
    static string toString(T)(T[] a, size_t size, size_t charLength) {
        // assert a !is null;
        // assert size > 0;

        // Copy each string into a perfectly sized char[]
        // Length of [ , , , ] == 2 * size
        char[] chars = new char[charLength + 2 * size];
        chars[0] = '[';
        int j = 1;
        for (int i = 0; i < size; i++) {
            if (i > 0) {
                chars[j++] = ',';
                chars[j++] = ' ';
            }
            string s = objectToString(a[i]);
            size_t len = s.length;
            chars[j .. j+len] = s[0..$];

            j += len;
        }
        chars[j] = ']';
        // assert j == chars.length - 1;
        return cast(string)(chars);
    }

    /** Optimized form of: key ~ "=" ~ val */
    static string mapEntryToString(K, V)(K key, V val) {
        string k, v;
        size_t klen, vlen;
        klen = (k = objectToString(key)).length;
        vlen = (v = objectToString(val)).length;
        char[] chars = new char[klen + vlen + 1];

        chars[0..klen] = k[0..klen];
        chars[klen] = '=';
        chars[klen + 1..$] = v[0..klen];
        
        return cast(string)(chars);
    }

    private static string objectToString(T)(T x) {
        // Extreme compatibility with StringBuilder.append(null)
        import std.range.primitives;
        static if(is(T == class)) {
            string s;
            return (x is null || (s = x.toString()).empty()) ? "null" : s;
        } else static if(is(T == string)) {
            return (x.empty()) ? "null" : x;
        } else {
            import std.conv;
            return to!string(x);
        }
    }
}
