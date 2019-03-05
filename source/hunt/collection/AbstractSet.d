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

module hunt.collection.AbstractSet;


import hunt.collection.AbstractCollection;
import hunt.collection.Collection;
import hunt.collection.Set;

import hunt.Exceptions;
import hunt.Functions;
import hunt.Object;


/**
 * This class provides a skeletal implementation of the <tt>Set</tt>
 * interface to minimize the effort required to implement this
 * interface. <p>
 *
 * The process of implementing a set by extending this class is identical
 * to that of implementing a Collection by extending AbstractCollection,
 * except that all of the methods and constructors in subclasses of this
 * class must obey the additional constraints imposed by the <tt>Set</tt>
 * interface (for instance, the add method must not permit addition of
 * multiple instances of an object to a set).<p>
 *
 * Note that this class does not override any of the implementations from
 * the <tt>AbstractCollection</tt> class.  It merely adds implementations
 * for <tt>equals</tt> and <tt>hashCode</tt>.<p>
 *
 * This class is a member of the
 * <a href="{@docRoot}/../technotes/guides/collections/index.html">
 * Java Collections Framework</a>.
 *
 * @param !(E) the type of elements maintained by this set
 *
 * @see Collection
 * @see AbstractCollection
 * @see Set
 */
abstract class AbstractSet(E) : AbstractCollection!E, Set!E {
    /**
     * Sole constructor.  (For invocation by subclass constructors, typically
     * implicit.)
     */
    protected this() {
    }

    // Comparison and hashing

    /**
     * Compares the specified object with this set for equality.  Returns
     * <tt>true</tt> if the given object is also a set, the two sets have
     * the same size, and every member of the given set is contained in
     * this set.  This ensures that the <tt>equals</tt> method works
     * properly across different implementations of the <tt>Set</tt>
     * interface.<p>
     *
     * This implementation first checks if the specified object is this
     * set; if so it returns <tt>true</tt>.  Then, it checks if the
     * specified object is a set whose size is identical to the size of
     * this set; if not, it returns false.  If so, it returns
     * <tt>containsAll((Collection) o)</tt>.
     *
     * @param o object to be compared for equality with this set
     * @return <tt>true</tt> if the specified object is equal to this set
     */
    override bool opEquals(Object o) {
        if (o is this)
            return true;

        Collection!E c = cast(Collection!E) o;
        if(c is null) return false;
        if (c.size() != size())
            return false;

        try {
            return containsAll(c);
        } catch (Exception) {
            return false;
        }
    }

    override bool opEquals(IObject o) {
        return opEquals(cast(Object) o);
    }
    /**
     * Returns the hash code value for this set.  The hash code of a set is
     * defined to be the sum of the hash codes of the elements in the set,
     * where the hash code of a <tt>null</tt> element is defined to be zero.
     * This ensures that <tt>s1.equals(s2)</tt> implies that
     * <tt>s1.toHash()==s2.toHash()</tt> for any two sets <tt>s1</tt>
     * and <tt>s2</tt>, as required by the general contract of
     * {@link Object#hashCode}.
     *
     * <p>This implementation iterates over the set, calling the
     * <tt>hashCode</tt> method on each element in the set, and adding up
     * the results.
     *
     * @return the hash code value for this set
     * @see Object#equals(Object)
     * @see Set#equals(Object)
     */
    override size_t toHash() @trusted nothrow {
        try {
            size_t h = 0;
            foreach(E item; this)
                h += hashOf(item);
            return h;
        }
        catch(Exception) {
            return 0;
        }
    }

    override string toString() {
        return super.toString();
    }    

    /**
     * Removes from this set all of its elements that are contained in the
     * specified collection (optional operation).  If the specified
     * collection is also a set, this operation effectively modifies this
     * set so that its value is the <i>asymmetric set difference</i> of
     * the two sets.
     *
     * <p>This implementation determines which is the smaller of this set
     * and the specified collection, by invoking the <tt>size</tt>
     * method on each.  If this set has fewer elements, then the
     * implementation iterates over this set, checking each element
     * returned by the iterator in turn to see if it is contained in
     * the specified collection.  If it is so contained, it is removed
     * from this set with the iterator's <tt>remove</tt> method.  If
     * the specified collection has fewer elements, then the
     * implementation iterates over the specified collection, removing
     * from this set each element returned by the iterator, using this
     * set's <tt>remove</tt> method.
     *
     * <p>Note that this implementation will throw an
     * <tt>UnsupportedOperationException</tt> if the iterator returned by the
     * <tt>iterator</tt> method does not implement the <tt>remove</tt> method.
     *
     * @param  c collection containing elements to be removed from this set
     * @return <tt>true</tt> if this set changed as a result of the call
     * @throws UnsupportedOperationException if the <tt>removeAll</tt> operation
     *         is not supported by this set
     * @throws ClassCastException if the class of an element of this set
     *         is incompatible with the specified collection
     * (<a href="Collection.html#optional-restrictions">optional</a>)
     * @throws NullPointerException if this set contains a null element and the
     *         specified collection does not permit null elements
     * (<a href="Collection.html#optional-restrictions">optional</a>),
     *         or if the specified collection is null
     * @see #remove(Object)
     * @see #contains(Object)
     */
    override bool removeAll(Collection!E c) {
        assert(c !is null);

        bool modified = false;

        // throw new NotImplementedException("");

        if (size() > c.size()) {
            foreach(E k; c)        {
                if(this.contains(k)) {
                    this.remove(k); modified = true;
                }
            }
            // for (Iterator<?> i = c.iterator(); i.hasNext(); )
            //     modified |= remove(i.next());
        } else {
            // for (Iterator<?> i = iterator(); i.hasNext(); ) {
            //     if (c.contains(i.next())) {
            //         i.remove();
            //         modified = true;
            //     }
            // }
            foreach(E k; this) {
                if(c.contains(k))  {
                    this.remove(k);
                    modified = true;
                }
            }
            
        }
        return modified;
    }

}


/**
*/
class EmptySet(E) : AbstractSet!(E) {

    // Iterator!(E) iterator() { return emptyIterator(); }

    override int size() {return 0;}
    override bool isEmpty() {return true;}
    override void clear() {}

    override bool contains(E obj) {return false;}
    override bool containsAll(Collection!E c) { return c.isEmpty(); }

    override E[] toArray() { return []; }

    // <T> T[] toArray(T[] a) {
    //     if (a.length > 0)
    //         a[0] = null;
    //     return a;
    // }

    // Override default methods in Collection
    // override
    // void forEach(Consumer<? super E> action) {
    //     Objects.requireNonNull(action);
    // }
    override bool removeIf(Predicate!E filter) {
        assert(filter !is null);
        return false;
    }

    override size_t toHash() @trusted nothrow {
        return 0;
    }
}