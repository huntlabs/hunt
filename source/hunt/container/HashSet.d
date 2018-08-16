module hunt.container.HashSet;


import hunt.container.AbstractSet;
import hunt.container.Set;

import std.algorithm;
import std.container.array;

/**
*/
class HashSet(E)
    : AbstractSet!E, Set!E // Cloneable , java.io.Serializable
{
    enum long serialVersionUID = -5024744406713321676L;

    protected Array!(E) _array;

    // Dummy value to associate with an Object in the backing Map
    // private static Object PRESENT = new Object();

    /**
     * Constructs a new, empty set; the backing <tt>HashMap</tt> instance has
     * default initial capacity (16) and load factor (0.75).
     */
    this() {
        // _array = new HashMap();
    }

    /**
     * Constructs a new set containing the elements in the specified
     * collection.  The <tt>HashMap</tt> is created with default load factor
     * (0.75) and an initial capacity sufficient to contain the elements in
     * the specified collection.
     *
     * @param c the collection whose elements are to be placed into this set
     * @throws NullPointerException if the specified collection is null
     */
    // this(Collection<? extends E> c) {
    //     _array = new HashMap<>(std.algorithm.max((int) (c.size()/.75f) + 1, 16));
    //     addAll(c);
    // }

    /**
     * Constructs a new, empty set; the backing <tt>HashMap</tt> instance has
     * the specified initial capacity and the specified load factor.
     *
     * @param      initialCapacity   the initial capacity of the hash map
     * @param      loadFactor        the load factor of the hash map
     * @throws     IllegalArgumentException if the initial capacity is less
     *             than zero, or if the load factor is nonpositive
     */
    // this(int initialCapacity, float loadFactor) {
    //     _array = new HashMap<>(initialCapacity, loadFactor);
    // }

    /**
     * Constructs a new, empty set; the backing <tt>HashMap</tt> instance has
     * the specified initial capacity and default load factor (0.75).
     *
     * @param      initialCapacity   the initial capacity of the hash table
     * @throws     IllegalArgumentException if the initial capacity is less
     *             than zero
     */
    this(int initialCapacity) {
        _array.reserve(initialCapacity);
    }

    /**
     * Constructs a new, empty linked hash set.  (This package private
     * constructor is only used by LinkedHashSet.) The backing
     * HashMap instance is a LinkedHashMap with the specified initial
     * capacity and the specified load factor.
     *
     * @param      initialCapacity   the initial capacity of the hash map
     * @param      loadFactor        the load factor of the hash map
     * @param      dummy             ignored (distinguishes this
     *             constructor from other int, float constructor.)
     * @throws     IllegalArgumentException if the initial capacity is less
     *             than zero, or if the load factor is nonpositive
     */
    // this(int initialCapacity, float loadFactor, bool dummy) {
    //     map = new LinkedHashMap<>(initialCapacity, loadFactor);
    // }

    /**
     * Returns an iterator over the elements in this set.  The elements
     * are returned in no particular order.
     *
     * @return an Iterator over the elements in this set
     * @see ConcurrentModificationException
     */
    // Iterator<E> iterator() {
    //     return _array.keySet().iterator();
    // }

    /**
     * Returns the number of elements in this set (its cardinality).
     *
     * @return the number of elements in this set (its cardinality)
     */
    override int size() {
        return cast(int)_array.length;
    }

    /**
     * Returns <tt>true</tt> if this set contains no elements.
     *
     * @return <tt>true</tt> if this set contains no elements
     */
    override bool isEmpty() {
        return _array.empty;
    }

    /**
     * Returns <tt>true</tt> if this set contains the specified element.
     * More formally, returns <tt>true</tt> if and only if this set
     * contains an element <tt>e</tt> such that
     * <tt>(o==null&nbsp;?&nbsp;e==null&nbsp;:&nbsp;o.equals(e))</tt>.
     *
     * @param o element whose presence in this set is to be tested
     * @return <tt>true</tt> if this set contains the specified element
     */
    override bool contains(E o) {
        return _array[].canFind(o);
    }

    /**
     * Adds the specified element to this set if it is not already present.
     * More formally, adds the specified element <tt>e</tt> to this set if
     * this set contains no element <tt>e2</tt> such that
     * <tt>(e==null&nbsp;?&nbsp;e2==null&nbsp;:&nbsp;e.equals(e2))</tt>.
     * If this set already contains the element, the call leaves the set
     * unchanged and returns <tt>false</tt>.
     *
     * @param e element to be added to this set
     * @return <tt>true</tt> if this set did not already contain the specified
     * element
     */
    override bool add(E e) {
        return _array.insertBack(e) >=0;
    }

    /**
     * Removes the specified element from this set if it is present.
     * More formally, removes an element <tt>e</tt> such that
     * <tt>(o==null&nbsp;?&nbsp;e==null&nbsp;:&nbsp;o.equals(e))</tt>,
     * if this set contains such an element.  Returns <tt>true</tt> if
     * this set contained the element (or equivalently, if this set
     * changed as a result of the call).  (This set will not contain the
     * element once the call returns.)
     *
     * @param o object to be removed from this set, if present
     * @return <tt>true</tt> if the set contained the specified element
     */
    bool remove(E o)
    {
        int index = indexOf(o);
        if(index < 0)   return false;
        _array.linearRemove(_array[index .. index+1]);
        return true;
    }
   
    private int indexOf(E o) {
        // return cast(int) _array[].indexOf(o);
        for(size_t i=0; i<_array.length; i++)
        {
            static if(is(E == class))
            {
                if(_array[i] is o) return cast(int)i;
            }
            else
            {
                if(_array[i] == o) return cast(int)i;
            }
        }

        return -1;
    }

    /**
     * Removes all of the elements from this set.
     * The set will be empty after this call returns.
     */
    override void clear() {
        _array.clear();
    }

    /**
     * Returns a shallow copy of this <tt>HashSet</tt> instance: the elements
     * themselves are not cloned.
     *
     * @return a shallow copy of this set
     */
    // 
    // Object clone() {
    //     try {
    //         HashSet<E> newSet = (HashSet<E>) super.clone();
    //         newSet.map = (HashMap<E, Object>) _array.clone();
    //         return newSet;
    //     } catch (CloneNotSupportedException e) {
    //         throw new InternalError(e);
    //     }
    // }

    /**
     * Save the state of this <tt>HashSet</tt> instance to a stream (that is,
     * serialize it).
     *
     * @serialData The capacity of the backing <tt>HashMap</tt> instance
     *             (int), and its load factor (float) are emitted, followed by
     *             the size of the set (the number of elements it contains)
     *             (int), followed by all of its elements (each an Object) in
     *             no particular order.
     */
    // private void writeObject(java.io.ObjectOutputStream s)
    //     throws java.io.IOException {
    //     // Write out any hidden serialization magic
    //     s.defaultWriteObject();

    //     // Write out HashMap capacity and load factor
    //     s.writeInt(_array.capacity());
    //     s.writeFloat(_array.loadFactor());

    //     // Write out size
    //     s.writeInt(_array.size());

    //     // Write out all elements in the proper order.
    //     for (E e : _array.keySet())
    //         s.writeObject(e);
    // }

    /**
     * Reconstitute the <tt>HashSet</tt> instance from a stream (that is,
     * deserialize it).
     */
    // private void readObject(java.io.ObjectInputStream s)
    //     throws java.io.IOException, ClassNotFoundException {
    //     // Read in any hidden serialization magic
    //     s.defaultReadObject();

    //     // Read capacity and verify non-negative.
    //     int capacity = s.readInt();
    //     if (capacity < 0) {
    //         throw new InvalidObjectException("Illegal capacity: " +
    //                                          capacity);
    //     }

    //     // Read load factor and verify positive and non NaN.
    //     float loadFactor = s.readFloat();
    //     if (loadFactor <= 0 || Float.isNaN(loadFactor)) {
    //         throw new InvalidObjectException("Illegal load factor: " +
    //                                          loadFactor);
    //     }

    //     // Read size and verify non-negative.
    //     int size = s.readInt();
    //     if (size < 0) {
    //         throw new InvalidObjectException("Illegal size: " +
    //                                          size);
    //     }

    //     // Set the capacity according to the size and load factor ensuring that
    //     // the HashMap is at least 25% full but clamping to maximum capacity.
    //     capacity = (int) std.algorithm.min(size * std.algorithm.min(1 / loadFactor, 4.0f),
    //             HashMap.MAXIMUM_CAPACITY);

    //     // Create backing HashMap
    //     map = (((HashSet<?>)this) instanceof LinkedHashSet ?
    //            new LinkedHashMap<E,Object>(capacity, loadFactor) :
    //            new HashMap<E,Object>(capacity, loadFactor));

    //     // Read in all elements in the proper order.
    //     for (int i=0; i<size; i++) {
    //         
    //             E e = (E) s.readObject();
    //         _array.put(e, PRESENT);
    //     }
    // }

    /**
     * Creates a <em><a href="Spliterator.html#binding">late-binding</a></em>
     * and <em>fail-fast</em> {@link Spliterator} over the elements in this
     * set.
     *
     * <p>The {@code Spliterator} reports {@link Spliterator#SIZED} and
     * {@link Spliterator#DISTINCT}.  Overriding implementations should document
     * the reporting of additional characteristic values.
     *
     * @return a {@code Spliterator} over the elements in this set
     * @since 1.8
     */
    // Spliterator<E> spliterator() {
    //     return new HashMap.KeySpliterator<E,Object>(map, 0, -1, 0, 0);
    // }

    override int opApply(scope int delegate(ref E) dg) {
        int result = 0;
        foreach(E v; _array) {
            result = dg(v);
            if(result != 0) return result;
        }
        return result;
    }
}