module hunt.container.AbstractList;

import std.algorithm;
import std.conv;
import std.container.array;

import hunt.container.AbstractCollection;
import hunt.container.List;

import hunt.lang.exception;
import hunt.util.functional;



abstract class AbstractList(E) : AbstractCollection!E, List!E {

 /**
     * The number of times this list has been <i>structurally modified</i>.
     * Structural modifications are those that change the size of the
     * list, or otherwise perturb it in such a fashion that iterations in
     * progress may yield incorrect results.
     *
     * <p>This field is used by the iterator and list iterator implementation
     * returned by the {@code iterator} and {@code listIterator} methods.
     * If the value of this field changes unexpectedly, the iterator (or list
     * iterator) will throw a {@code ConcurrentModificationException} in
     * response to the {@code next}, {@code remove}, {@code previous},
     * {@code set} or {@code add} operations.  This provides
     * <i>fail-fast</i> behavior, rather than non-deterministic behavior in
     * the face of concurrent modification during iteration.
     *
     * <p><b>Use of this field by subclasses is optional.</b> If a subclass
     * wishes to provide fail-fast iterators (and list iterators), then it
     * merely has to increment this field in its {@code add(int, E)} and
     * {@code remove(int)} methods (and any other methods that it overrides
     * that result in structural modifications to the list).  A single call to
     * {@code add(int, E)} or {@code remove(int)} must add no more than
     * one to this field, or the iterators (and list iterators) will throw
     * bogus {@code ConcurrentModificationExceptions}.  If an implementation
     * does not wish to provide fail-fast iterators, this field may be
     * ignored.
     */
    protected int modCount = 0;

    /**
     * Sole constructor.  (For invocation by subclass constructors, typically
     * implicit.)
     */
    protected this() {
    }

    /**
     * Appends the specified element to the end of this list (optional
     * operation).
     *
     * <p>Lists that support this operation may place limitations on what
     * elements may be added to this list.  In particular, some
     * lists will refuse to add null elements, and others will impose
     * restrictions on the type of elements that may be added.  List
     * classes should clearly specify in their documentation any restrictions
     * on what elements may be added.
     *
     * <p>This implementation calls {@code add(size(), e)}.
     *
     * <p>Note that this implementation throws an
     * {@code UnsupportedOperationException} unless
     * {@link #add(int, Object) add(int, E)} is overridden.
     *
     * @param e element to be appended to this list
     * @return {@code true} (as specified by {@link Collection#add})
     * @throws UnsupportedOperationException if the {@code add} operation
     *         is not supported by this list
     * @throws ClassCastException if the class of the specified element
     *         prevents it from being added to this list
     * @throws NullPointerException if the specified element is null and this
     *         list does not permit null elements
     * @throws IllegalArgumentException if some property of this element
     *         prevents it from being added to this list
     */
    // bool add(E e) { throw new UnsupportedOperationException(""); }

    /**
     * {@inheritDoc}
     *
     * @throws IndexOutOfBoundsException {@inheritDoc}
     */
    E get(int index) { throw new UnsupportedOperationException(""); }
    
    E opIndex(int index) { return get(index); }

    /**
     * {@inheritDoc}
     *
     * <p>This implementation always throws an
     * {@code UnsupportedOperationException}.
     *
     * @throws UnsupportedOperationException {@inheritDoc}
     * @throws ClassCastException            {@inheritDoc}
     * @throws NullPointerException          {@inheritDoc}
     * @throws IllegalArgumentException      {@inheritDoc}
     * @throws IndexOutOfBoundsException     {@inheritDoc}
     */
    E set(int index, E element) {
        throw new UnsupportedOperationException("");
    }

    /**
     * {@inheritDoc}
     *
     * <p>This implementation always throws an
     * {@code UnsupportedOperationException}.
     *
     * @throws UnsupportedOperationException {@inheritDoc}
     * @throws ClassCastException            {@inheritDoc}
     * @throws NullPointerException          {@inheritDoc}
     * @throws IllegalArgumentException      {@inheritDoc}
     * @throws IndexOutOfBoundsException     {@inheritDoc}
     */
    void add(int index, E element) {
        throw new UnsupportedOperationException("");
    }

    /**
     * {@inheritDoc}
     *
     * <p>This implementation always throws an
     * {@code UnsupportedOperationException}.
     *
     * @throws UnsupportedOperationException {@inheritDoc}
     * @throws IndexOutOfBoundsException     {@inheritDoc}
     */
    E removeAt(int index) { throw new UnsupportedOperationException("");  }

    bool remove(E o) { throw new UnsupportedOperationException(""); }


    // Search Operations

    /**
     * {@inheritDoc}
     *
     * <p>This implementation first gets a list iterator (with
     * {@code listIterator()}).  Then, it iterates over the list until the
     * specified element is found or the end of the list is reached.
     *
     * @throws ClassCastException   {@inheritDoc}
     * @throws NullPointerException {@inheritDoc}
     */
    int indexOf(E o) { throw new UnsupportedOperationException(""); }
    
    /**
     * {@inheritDoc}
     *
     * <p>This implementation first gets a list iterator that points to the end
     * of the list (with {@code listIterator(size())}).  Then, it iterates
     * backwards over the list until the specified element is found, or the
     * beginning of the list is reached.
     *
     * @throws ClassCastException   {@inheritDoc}
     * @throws NullPointerException {@inheritDoc}
     */
    int lastIndexOf(E o) { throw new UnsupportedOperationException(""); }


    // Bulk Operations

    /**
     * Removes all of the elements from this list (optional operation).
     * The list will be empty after this call returns.
     *
     * <p>This implementation calls {@code removeRange(0, size())}.
     *
     * <p>Note that this implementation throws an
     * {@code UnsupportedOperationException} unless {@code remove(int
     * index)} or {@code removeRange(int fromIndex, int toIndex)} is
     * overridden.
     *
     * @throws UnsupportedOperationException if the {@code clear} operation
     *         is not supported by this list
     */
    // void clear() { throw new UnsupportedOperationException(""); }

      // Comparison and hashing

    /**
     * Compares the specified object with this list for equality.  Returns
     * {@code true} if and only if the specified object is also a list, both
     * lists have the same size, and all corresponding pairs of elements in
     * the two lists are <i>equal</i>.  (Two elements {@code e1} and
     * {@code e2} are <i>equal</i> if {@code (e1==null ? e2==null :
     * e1.equals(e2))}.)  In other words, two lists are defined to be
     * equal if they contain the same elements in the same order.<p>
     *
     * This implementation first checks if the specified object is this
     * list. If so, it returns {@code true}; if not, it checks if the
     * specified object is a list. If not, it returns {@code false}; if so,
     * it iterates over both lists, comparing corresponding pairs of elements.
     * If any comparison returns {@code false}, this method returns
     * {@code false}.  If either iterator runs out of elements before the
     * other it returns {@code false} (as the lists are of unequal length);
     * otherwise it returns {@code true} when the iterations complete.
     *
     * @param o the object to be compared for equality with this list
     * @return {@code true} if the specified object is equal to this list
     */
    override public bool opEquals(Object o) {
        if (o is this)
            return true;
        List!E e2 = cast(List!E)o;
        if (e2 is null)
            return false;
        
        if(this.size() != e2.size())
            return false;

        for(int i= 0 ; i < this.size();i++)
        {
            if(this.get(i)  != e2.get(i))
                return false;
        }
 
        return true;
    }

    /**
     * Returns the hash code value for this list.
     *
     * <p>This implementation uses exactly the code that is used to define the
     * list hash function in the documentation for the {@link List#hashCode}
     * method.
     *
     * @return the hash code value for this list
     */
    override size_t toHash() @trusted nothrow {
        size_t hashCode = 1;
        try
        {
            static if(is(E == class)) {
            foreach (E e ; this)
                hashCode = 31*hashCode + (e is null ? 0 : (cast(Object)e).toHash());
            } else {
                foreach (E e ; this)
                    hashCode = 31*hashCode + hashOf(e);
            }
        }
        catch(Exception e)
        {

        }
        
    
        return hashCode;
    }

    override int opApply(scope int delegate(ref E) dg)
    {
        return 0;
    }

    // List!(E) opCast(C)(C c) nothrow
    //     //if(is(C == immutable (E)[]))
    // {
    //     return cast(List!(E))c;
    // }
    /**
     * {@inheritDoc}
     *
     * <p>This implementation gets an iterator over the specified collection
     * and iterates over it, inserting the elements obtained from the
     * iterator into this list at the appropriate position, one at a time,
     * using {@code add(int, E)}.
     * Many implementations will override this method for efficiency.
     *
     * <p>Note that this implementation throws an
     * {@code UnsupportedOperationException} unless
     * {@link #add(int, Object) add(int, E)} is overridden.
     *
     * @throws UnsupportedOperationException {@inheritDoc}
     * @throws ClassCastException            {@inheritDoc}
     * @throws NullPointerException          {@inheritDoc}
     * @throws IllegalArgumentException      {@inheritDoc}
     * @throws IndexOutOfBoundsException     {@inheritDoc}
     */
    // bool addAll(int index, Collection<E> c) {
    //     rangeCheckForAdd(index);
    //     bool modified = false;
    //     for (E e : c) {
    //         add(index++, e);
    //         modified = true;
    //     }
    //     return modified;
    // }
}


class EmptyList(E): AbstractList!E {
    // private static long serialVersionUID = 8842843931221139166L;

    override int size() {return 0;}
    override bool isEmpty() {return true;}

    override bool contains(E obj) {return false;}
    // override bool containsAll(Collection!E c) { return c.isEmpty(); }

    override E[] toArray() { return new E[0]; }

    T[] toArray(T)(T[] a) {
        if (a.length > 0)
            a[0] = null;
        return a;
    }

    override E get(int index) {
        throw new IndexOutOfBoundsException("Index: " ~ index.to!string);
    }

    override bool add(E e) {
        throw new UnsupportedOperationException("");
    }

    override E removeAt(int index) { throw new IndexOutOfBoundsException("Index: " ~ index.to!string); }

    override bool remove(E o) { return false; }

    override int indexOf(E o) {
        return -1;
    }

    override int lastIndexOf(E o) {
        return -1;
    }


    override bool opEquals(Object o) {
        return (typeid(o) == typeid(List!E)) && (cast(List!E)o).isEmpty();
    }

    int hashCode() { return 1; }

    override size_t toHash() { return 1; }

    // override
    // bool removeIf(Predicate!E filter) {
    //     assert(filter !is null);
    //     return false;
    // }

    // override
    // void replaceAll(UnaryOperator!E operator) {
    //     Objects.requireNonNull(operator);
    // }
    // override
    // void sort(Comparator<E> c) {
    // }

    // Override default methods in Collection
    override int opApply(scope int delegate(ref E) dg)
    {
        return 0;
    }

    // override
    // Spliterator!E spliterator() { return Spliterators.emptySpliterator(); }

    // // Preserves singleton property
    // private Object readResolve() {
    //     return EMPTY_LIST;
    // }
}