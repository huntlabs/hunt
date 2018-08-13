module hunt.container.AbstractCollection;

import hunt.util.exception;
import hunt.container.Collection;

abstract class AbstractCollection(E) : Collection!E {
    /**
     * Sole constructor.  (For invocation by subclass constructors, typically
     * implicit.)
     */
    protected this() {
    }

    // Query Operations


    abstract int size();

    /**
     * {@inheritDoc}
     *
     * <p>This implementation returns <tt>size() == 0</tt>.
     */
    bool isEmpty() {
        return size() == 0;
    }

    /**
     * {@inheritDoc}
     *
     * <p>This implementation iterates over the elements in the collection,
     * checking each element in turn for equality with the specified element.
     *
     * @throws ClassCastException   {@inheritDoc}
     * @throws NullPointerException {@inheritDoc}
     */
    bool contains(E o) {
        // Iterator<E> it = iterator();
        // if (o==null) {
        //     while (it.hasNext())
        //         if (it.next()==null)
        //             return true;
        // } else {
        //     while (it.hasNext())
        //         if (o.equals(it.next()))
        //             return true;
        // }
        // return false;

        throw new NotImplementedException();
    }

    bool add(E e) {
        throw new NotImplementedException();
    }

    // E get(int index) { throw new UnsupportedOperationException(); }

    /**
     * {@inheritDoc}
     *
     * <p>This implementation iterates over the specified collection, and adds
     * each object returned by the iterator to this collection, in turn.
     *
     * <p>Note that this implementation will throw an
     * <tt>UnsupportedOperationException</tt> unless <tt>add</tt> is
     * overridden (assuming the specified collection is non-empty).
     *
     * @throws UnsupportedOperationException {@inheritDoc}
     * @throws ClassCastException            {@inheritDoc}
     * @throws NullPointerException          {@inheritDoc}
     * @throws IllegalArgumentException      {@inheritDoc}
     * @throws IllegalStateException         {@inheritDoc}
     *
     * @see #add(Object)
     */
    bool addAll(Collection!E c) {
        bool modified = false;
        foreach (E e ; c)
            if (add(e))
                modified = true;
        return modified;
    }

    void clear() { throw new UnsupportedOperationException(""); }

    int opApply(scope int delegate(ref E) dg)  {
        throw new NotImplementedException();
    }
    
    // int opApply(scope int delegate(MapEntry!(E) entry) dg) {
    //     throw new NotImplementedException();
    // }

    /**
     * {@inheritDoc}
     *
     * <p>This implementation returns an array containing all the elements
     * returned by this collection's iterator, in the same order, stored in
     * consecutive elements of the array, starting with index {@code 0}.
     * The length of the returned array is equal to the number of elements
     * returned by the iterator, even if the size of this collection changes
     * during iteration, as might happen if the collection permits
     * concurrent modification during iteration.  The {@code size} method is
     * called only as an optimization hint; the correct result is returned
     * even if the iterator returns a different number of elements.
     *
     * <p>This method is equivalent to:
     *
     *  <pre> {@code
     * List<E> list = new ArrayList<E>(size());
     * for (E e : this)
     *     list.add(e);
     * return list.toArray();
     * }</pre>
     */
    E[] toArray() {
        throw new NotImplementedException("toArray");
     }

    override size_t toHash() @trusted nothrow
    {
        return super.toHash();
    }

    override string toString()
    {
        return super.toString();
    }
}