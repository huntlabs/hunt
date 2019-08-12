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

module hunt.Boolean;

import hunt.Nullable;
import hunt.text;
import std.traits;

import std.concurrency : initOnce;

/**
 * The Boolean class wraps a value of the primitive type
 * {@code bool} in an object. An object of type
 * {@code Boolean} contains a single field whose type is
 * {@code bool}.
 * <p>
 * In addition, this class provides many methods for
 * converting a {@code bool} to a {@code string} and a
 * {@code string} to a {@code bool}, as well as other
 * constants and methods useful when dealing with a
 * {@code bool}.
 *
 * @author  Arthur van Hoff
 * @since   JDK1.0
 */
class Boolean : Nullable!bool {
    /**
     * The {@code Boolean} object corresponding to the primitive
     * value {@code true}.
     */
    static Boolean TRUE() {
        __gshared Boolean inst;
        return initOnce!inst(new Boolean(true));
    }

    /**
     * The {@code Boolean} object corresponding to the primitive
     * value {@code false}.
     */
    static Boolean FALSE() {
        __gshared Boolean inst;
        return initOnce!inst(new Boolean(false));
    }


    /**
     * The Class object representing the primitive type bool.
     *
     * @since   JDK1.1
    //  */
    // @SuppressWarnings("unchecked")
    // static  Class<Boolean> TYPE = (Class<Boolean>) Class.getPrimitiveClass("bool");

    /**
     * Allocates a {@code Boolean} object representing the
     * {@code value} argument.
     *
     * <p><b>Note: It is rarely appropriate to use this constructor.
     * Unless a <i>new</i> instance is required, the static factory
     * {@link #valueOf(bool)} is generally a better choice. It is
     * likely to yield significantly better space and time performance.</b>
     *
     * @param   value   the value of the {@code Boolean}.
     */
    static private bool assign(T)(T arg) @safe {
        bool value;
        static if (is(T : typeof(null))) {
            value = false;
        }
        else static if (is(T : string)) {
            string t = arg;
            if (t.length != 0)
                value = true;
            else
                value = false;
        }
        else static if (is(T : bool)) {
            value = arg;
        }
        else static if (is(T : ulong) && isUnsigned!T) {
            value = (arg != 0 ? true : false);
        }
        else static if (is(T : long)) {
            value = (arg != 0 ? true : false);
        }
        else {
            static assert(false, text(`unable to convert type "`, T.stringof, `" to Boolean`));
        }

        return value;
    }

    this() {
        super();
    }
    
    this(bool v) {
        super(v);
    }
    
    this(long v) {
        super(v != 0 ? true : false);
    }
    
    this(ulong v) {
        super(v != 0 ? true : false);
    }

    this(Boolean v) {
        super(v.value);
    }

    // this(T)(T value) if (!isStaticArray!T) {
    //     super(assign(value));
    // }

    // /// Ditto
    // this(T)(ref T arg) if (isStaticArray!T) {
    //     super(arg.booleanValue());
    // }
    // /// Ditto
    // this(T : Boolean)(inout T arg) inout {
    //     super(arg.booleanValue());
    // }

    /**
     * Allocates a {@code Boolean} object representing the value
     * {@code true} if the string argument is not {@code null}
     * and is equal, ignoring case, to the string {@code "true"}.
     * Otherwise, allocate a {@code Boolean} object representing the
     * value {@code false}. Examples:<p>
     * {@code new Boolean("True")} produces a {@code Boolean} object
     * that represents {@code true}.<br>
     * {@code new Boolean("yes")} produces a {@code Boolean} object
     * that represents {@code false}.
     *
     * @param   s   the string to be converted to a {@code Boolean}.
     */
    this(string s) {
        this(parseBoolean(s));
    }

    /**
     * Parses the string argument as a bool.  The {@code bool}
     * returned represents the value {@code true} if the string argument
     * is not {@code null} and is equal, ignoring case, to the string
     * {@code "true"}. <p>
     * Example: {@code Boolean.parseBoolean("True")} returns {@code true}.<br>
     * Example: {@code Boolean.parseBoolean("yes")} returns {@code false}.
     *
     * @param      s   the {@code string} containing the bool
     *                 representation to be parsed
     * @return     the bool represented by the string argument
     */
    static bool parseBoolean(string s) {
        return ((s.length != 0) && equalsIgnoreCase(s, "true"));
    }

    /**
     * Returns the value of this {@code Boolean} object as a bool
     * primitive.
     *
     * @return  the primitive {@code bool} value of this object.
     */
    bool booleanValue() {
        return value;
    }

    /**
     * Returns a {@code Boolean} instance representing the specified
     * {@code bool} value.  If the specified {@code bool} value
     * is {@code true}, this method returns {@code Boolean.TRUE};
     * if it is {@code false}, this method returns {@code Boolean.FALSE}.
     * If a new {@code Boolean} instance is not required, this method
     * should generally be used in preference to the constructor
     * {@link #Boolean(bool)}, as this method is likely to yield
     * significantly better space and time performance.
     *
     * @param  b a bool value.
     * @return a {@code Boolean} instance representing {@code b}.
     * @since  1.4
     */
    static Boolean valueOf(bool b) {
        return (b ? TRUE : FALSE);
    }

    /**
     * Returns a {@code Boolean} with a value represented by the
     * specified string.  The {@code Boolean} returned represents a
     * true value if the string argument is not {@code null}
     * and is equal, ignoring case, to the string {@code "true"}.
     *
     * @param   s   a string.
     * @return  the {@code Boolean} value represented by the string.
     */
    static Boolean valueOf(string s) {
        return parseBoolean(s) ? TRUE : FALSE;
    }

    /**
     * Returns a {@code string} object representing the specified
     * bool.  If the specified bool is {@code true}, then
     * the string {@code "true"} will be returned, otherwise the
     * string {@code "false"} will be returned.
     *
     * @param b the bool to be converted
     * @return the string representation of the specified {@code bool}
     */
    static string toString(bool b) {
        return b ? "true" : "false";
    }

    /**
     * Returns a {@code string} object representing this Boolean's
     * value.  If this object represents the value {@code true},
     * a string equal to {@code "true"} is returned. Otherwise, a
     * string equal to {@code "false"} is returned.
     *
     * @return  a string representation of this object.
     */
    override string toString() {
        return value ? "true" : "false";
    }

    /**
     * Returns a hash code for this {@code Boolean} object.
     *
     * @return  the integer {@code 1231} if this object represents
     * {@code true}; returns the integer {@code 1237} if this
     * object represents {@code false}.
     */
    override size_t toHash() @safe nothrow {
        return value ? 1231 : 1237;
    }

    /**
     * Returns a hash code for a {@code bool} value; compatible with
     * {@code Boolean.hashCode()}.
     *
     * @param value the value to hash
     * @return a hash code value for a {@code bool} value.
     */
    // static size_t hashCode(bool value) {
    //     return value ? 1231 : 1237;
    // }

    /**
     * Returns {@code true} if and only if the argument is not
     * {@code null} and is a {@code Boolean} object that
     * represents the same {@code bool} value as this object.
     *
     * @param   obj   the object to compare with.
     * @return  {@code true} if the Boolean objects represent the
     *          same value; {@code false} otherwise.
     */
    // override bool opEquals(Object obj) {
    //     if (cast(Boolean) obj !is null) {
    //         return value == (cast(Boolean) obj).booleanValue();
    //     }
    //     return false;
    // }

    // void opAssign(T)(T arg) if (!isStaticArray!T && !is(T : Boolean)) {
    //     this._value = assign(arg);
    // }

    // void opAssign(T)(ref T arg) if (isStaticArray!T) {
    //     value = arg.booleanValue;
    // }

    /**
     * Returns {@code true} if and only if the system property
     * named by the argument exists and is equal to the string
     * {@code "true"}. (Beginning with version 1.0.2 of the
     * Java<small><sup>TM</sup></small> platform, the test of
     * this string is case insensitive.) A system property is accessible
     * through {@code getProperty}, a method defined by the
     * {@code System} class.
     * <p>
     * If there is no property with the specified name, or if the specified
     * name is empty or null, then {@code false} is returned.
     *
     * @param   name   the system property name.
     * @return  the {@code bool} value of the system property.
     * @throws  SecurityException for the same reasons as
     *          {@link System#getProperty(string) System.getProperty}
     * @see     java.lang.System#getProperty(java.lang.string)
     * @see     java.lang.System#getProperty(java.lang.string, java.lang.string)
     */
    // static bool getBoolean(string name) {
    //     bool result = false;
    //     try {
    //         result = parseBoolean(System.getProperty(name));
    //     } catch (IllegalArgumentException | NullPointerException e) {
    //     }
    //     return result;
    // }

    /**
     * Compares this {@code Boolean} instance with another.
     *
     * @param   b the {@code Boolean} instance to be compared
     * @return  zero if this object represents the same bool value as the
     *          argument; a positive value if this object represents true
     *          and the argument represents false; and a negative value if
     *          this object represents false and the argument represents true
     * @throws  NullPointerException if the argument is {@code null}
     * @see     Comparable
     * @since  1.5
     */
    int compareTo(Boolean b) {
        return compare(this.value, b.value);
    }

    /**
     * Compares two {@code bool} values.
     * The value returned is identical to what would be returned by:
     * <pre>
     *    Boolean.valueOf(x).compareTo(Boolean.valueOf(y))
     * </pre>
     *
     * @param  x the first {@code bool} to compare
     * @param  y the second {@code bool} to compare
     * @return the value {@code 0} if {@code x == y};
     *         a value less than {@code 0} if {@code !x && y}; and
     *         a value greater than {@code 0} if {@code x && !y}
     */
    static int compare(bool x, bool y) {
        return (x == y) ? 0 : (x ? 1 : -1);
    }

    /**
     * Returns the result of applying the logical AND operator to the
     * specified {@code bool} operands.
     *
     * @param a the first operand
     * @param b the second operand
     * @return the logical AND of {@code a} and {@code b}
     * @see hunt.util.functional.BinaryOperator
     */
    static bool logicalAnd(bool a, bool b) {
        return a && b;
    }

    /**
     * Returns the result of applying the logical OR operator to the
     * specified {@code bool} operands.
     *
     * @param a the first operand
     * @param b the second operand
     * @return the logical OR of {@code a} and {@code b}
     * @see hunt.util.functional.BinaryOperator
     */
    static bool logicalOr(bool a, bool b) {
        return a || b;
    }

    /**
     * Returns the result of applying the logical XOR operator to the
     * specified {@code bool} operands.
     *
     * @param a the first operand
     * @param b the second operand
     * @return  the logical XOR of {@code a} and {@code b}
     * @see hunt.util.functional.BinaryOperator
     */
    static bool logicalXor(bool a, bool b) {
        return a ^ b;
    }
}

