module hunt.container.AbstractCollection;

import hunt.util.exception;
import hunt.container.Collection;

import std.array;
import std.conv;

/**
 * This class provides a skeletal implementation of the {@code Collection}
 * interface, to minimize the effort required to implement this interface. <p>
 *
 * To implement an unmodifiable collection, the programmer needs only to
 * extend this class and provide implementations for the {@code iterator} and
 * {@code size} methods.  (The iterator returned by the {@code iterator}
 * method must implement {@code hasNext} and {@code next}.)<p>
 *
 * To implement a modifiable collection, the programmer must additionally
 * override this class's {@code add} method (which otherwise throws an
 * {@code UnsupportedOperationException}), and the iterator returned by the
 * {@code iterator} method must additionally implement its {@code remove}
 * method.<p>
 *
 * The programmer should generally provide a void (no argument) and
 * {@code Collection} constructor, as per the recommendation in the
 * {@code Collection} interface specification.<p>
 *
 * The documentation for each non-abstract method in this class describes its
 * implementation in detail.  Each of these methods may be overridden if
 * the collection being implemented admits a more efficient implementation.<p>
 *
 * This class is a member of the
 * <a href="{@docRoot}/java/util/package-summary.html#CollectionsFramework">
 * Java Collections Framework</a>.
 *
 * @author  Josh Bloch
 * @author  Neal Gafter
 * @see Collection
 * @since 1.2
 */
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
        // throw new NotImplementedException("toArray");
        if(size() == 0)
            return [];

        E[] r = new E[size()];
        int i=0;
        foreach(E e; this)
            r[i++] = e;
        return r;
     }

    override size_t toHash() @trusted nothrow
    {
        return super.toHash();
    }

    //  String conversion

    /**
     * Returns a string representation of this collection.  The string
     * representation consists of a list of the collection's elements in the
     * order they are returned by its iterator, enclosed in square brackets
     * ({@code "[]"}).  Adjacent elements are separated by the characters
     * {@code ", "} (comma and space).  Elements are converted to strings as
     * by {@link String#valueOf(Object)}.
     *
     * @return a string representation of this collection
     */
    override string toString()
    {
        if(size() == 0)
            return "[]";
        
        Appender!string sb;
        sb.put("[");
        bool isFirst = true;
        foreach(E e; this)
        {
           if(!isFirst) sb.put(", ");
            static if(is(E == class))
                sb.put(e is this ? "(this Collection)" : e.toString());
            else
                sb.put(e.to!string());
            isFirst = false;
        }
        sb.put(']');
        return sb.data;
    }
}