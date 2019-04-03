module hunt.Enum;

import hunt.Exceptions;
import hunt.util.Common;
import hunt.util.Comparator;

import std.traits;

/**
*/
interface Enum(E) : Comparable!E {
    
    string name();

    int ordinal();

    string toString();
}

/**
 * This is the common base class of all enumeration types.
 */
abstract class AbstractEnum(E) : Enum!E {

    /**
     * Sole constructor.  Programmers cannot invoke this constructor.
     * It is for use by code emitted by the compiler in response to
     * enum type declarations.
     *
     * @param name - The name of this enum constant, which is the identifier
     *               used to declare it.
     * @param ordinal - The ordinal of this enumeration constant (its position
     *         in the enum declaration, where the initial constant is assigned
     *         an ordinal of zero).
     */
    protected this(string name, int ordinal) {
        this._name = name;
        this._ordinal = ordinal;
    }
    
    /**
     * The name of this enum constant, as declared in the enum declaration.
     * Most programmers should use the {@link #toString} method rather than
     * accessing this field.
     */
    protected string _name;

    /**
     * Returns the name of this enum constant, exactly as declared in its
     * enum declaration.
     *
     * <b>Most programmers should use the {@link #toString} method in
     * preference to this one, as the toString method may return
     * a more user-friendly name.</b>  This method is designed primarily for
     * use in specialized situations where correctness depends on getting the
     * exact name, which will not vary from release to release.
     *
     * @return the name of this enum constant
     */
    final string name() {
        return _name;
    }

    /**
     * The ordinal of this enumeration constant (its position
     * in the enum declaration, where the initial constant is assigned
     * an ordinal of zero).
     *
     * Most programmers will have no use for this field.  It is designed
     * for use by sophisticated enum-based data structures, such as
     * {@link java.util.EnumSet} and {@link java.util.EnumMap}.
     */
    protected int _ordinal;

    /**
     * Returns the ordinal of this enumeration constant (its position
     * in its enum declaration, where the initial constant is assigned
     * an ordinal of zero).
     *
     * Most programmers will have no use for this method.  It is
     * designed for use by sophisticated enum-based data structures, such
     * as {@link java.util.EnumSet} and {@link java.util.EnumMap}.
     *
     * @return the ordinal of this enumeration constant
     */
    final int ordinal() {
        return _ordinal;
    }

    /**
     * Returns the name of this enum constant, as contained in the
     * declaration.  This method may be overridden, though it typically
     * isn't necessary or desirable.  An enum type should override this
     * method when a more "programmer-friendly" string form exists.
     *
     * @return the name of this enum constant
     */
    override string toString() {
        return _name;
    }

    /**
     * Returns true if the specified object is equal to this
     * enum constant.
     *
     * @param other the object to be compared for equality with this object.
     * @return  true if the specified object is equal to this
     *          enum constant.
     */
    final override bool opEquals(Object other) {
        return this is other;
    }

    /**
     * Returns a hash code for this enum constant.
     *
     * @return a hash code for this enum constant.
     */
    // final int hashCode() {
    //     return super.hashCode();
    // }

    /**
     * Throws CloneNotSupportedException.  This guarantees that enums
     * are never cloned, which is necessary to preserve their "singleton"
     * status.
     *
     * @return (never returns)
     */
    // protected final Object clone() {
    //     throw new CloneNotSupportedException();
    // }

    /**
     * Compares this enum with the specified object for order.  Returns a
     * negative integer, zero, or a positive integer as this object is less
     * than, equal to, or greater than the specified object.
     *
     * Enum constants are only comparable to other enum constants of the
     * same enum type.  The natural order implemented by this
     * method is the order in which the constants are declared.
     */
    final int opCmp(E o) {
        Enum!E other = cast(Enum!E) o;
        Enum!E self = this;
        if (other is null)
            throw new NullPointerException();
        return compare(self.ordinal, other.ordinal);
    }
}





/**
 * Returns the enum constant of the specified enum type with the
 * specified name.  The name must match exactly an identifier used
 * to declare an enum constant in this type.  (Extraneous whitespace
 * characters are not permitted.)
 *
 * <p>Note that for a particular enum type {@code T}, the
 * implicitly declared {@code static T valueOf(string)}
 * method on that enum may be used instead of this method to map
 * from a name to the corresponding enum constant.  All the
 * constants of an enum type can be obtained by calling the
 * implicit {@code static T[] values()} method of that
 * type.
 *
 * @param <T> The enum type whose constant is to be returned
 * @param enumType the {@code Class} object of the enum type from which
 *      to return a constant
 * @param name the name of the constant to return
 * @return the enum constant of the specified enum type with the
 *      specified name
 * @throws IllegalArgumentException if the specified enum type has
 *         no constant with the specified name, or the specified
 *         class object does not represent an enum type
 */    
T valueOf(T)(string name, T defaultValue = T.init) if(is(T : Enum!(T))) {
    static if(hasStaticMember!(T, "values")) {
            enum string code = generateLocator!(T, "values", name.stringof, defaultValue.stringof)();
            mixin(code);
    } else {
        static assert(false, "Can't find static member values in " ~ fullyQualifiedName!T ~ ".");
    }
}

 private string generateLocator(T, string memberName, string paramName, string defaultValue)() 
    if(is(T : Enum!(T))) {
    import std.format;
    string s;

    s = format(`foreach(T t; T.%1$s) {
            if(t.name() == %2$s)
                return t;
        }
        debug {
            throw new IllegalArgumentException("Can't locate the member: " ~ %2$s ~ " in " ~ typeid(T).name ~ ".%1$s");
        } else {
            return %3$s;
        }`, memberName, paramName, defaultValue);

    return s;
}