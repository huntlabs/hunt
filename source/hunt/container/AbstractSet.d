module hunt.container.AbstractSet;


import hunt.container.AbstractCollection;
import hunt.container.Collection;
import hunt.container.Set;

import hunt.util.exception;

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
    // bool equals(Object o) {
    //     if (o == this)
    //         return true;

    //     if (!(o instanceof Set))
    //         return false;
    //     Collection<?> c = (Collection<?>) o;
    //     if (c.size() != size())
    //         return false;
    //     try {
    //         return containsAll(c);
    //     } catch (ClassCastException unused)   {
    //         return false;
    //     } catch (NullPointerException unused) {
    //         return false;
    //     }
    // }

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
    // int toHash() {
    //     int h = 0;
    //     Iterator<E> i = iterator();
    //     while (i.hasNext()) {
    //         E obj = i.next();
    //         if (obj != null)
    //             h += obj.toHash();
    //     }
    //     return h;
    // }

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
    bool removeAll(Collection!E c) {
        assert(c !is null);

        bool modified = false;

        throw new NotImplementedException("");

        // if (size() > c.size()) {
        //     for (Iterator<?> i = c.iterator(); i.hasNext(); )
        //         modified |= remove(i.next());
        // } else {
        //     for (Iterator<?> i = iterator(); i.hasNext(); ) {
        //         if (c.contains(i.next())) {
        //             i.remove();
        //             modified = true;
        //         }
        //     }
        // }
        // return modified;
    }

}