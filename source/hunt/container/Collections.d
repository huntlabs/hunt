module hunt.container.Collections;


import hunt.container.AbstractList;
import hunt.container.AbstractMap;
import hunt.container.AbstractSet;
import hunt.container.Collection;
import hunt.container.Enumeration;
import hunt.container.List;
import hunt.container.NavigableSet;
import hunt.container.Map;
import hunt.container.Set;
import hunt.container.SortedSet;
import hunt.container.TreeSet;


import hunt.util.exception;
import hunt.util.functional;

import std.conv;
import std.range;



/**
*/
class Collections {
    // Suppresses default constructor, ensuring non-instantiability.

    private this() {
    }

    static Enumeration!T enumeration(T=string)(InputRange!T range)
    {
        return new RangeEnumeration!T(range);
    }

    static Enumeration!T enumeration(T=string)(T[] range)
    {
        return new RangeEnumeration!T(inputRangeObject(range));
    }

    /**
     * Returns true if the specified arguments are equal, or both null.
     *
     * NB: Do not replace with Object.equals until JDK-8015417 is resolved.
     */
    // static bool eq(Object o1, Object o2) {
    //     return o1 is null ? o2 is null : o1.opEquals(o2);
    // }

    /**
     * Returns an empty map (immutable).  This map is serializable.
     *
     * !(p)This example illustrates the type-safe way to obtain an empty map:
     * !(pre)
     *     Map&lt;string, Date&gt; s = Collections.emptyMap();
     * !(/pre)
     * @implNote Implementations of this method need not create a separate
     * {@code Map} object for each call.  Using this method is likely to have
     * comparable cost to using the like-named field.  (Unlike this method, the
     * field does not provide type safety.)
     *
     * @param !(K) the class of the map keys
     * @param !(V) the class of the map values
     * @return an empty map
     * @see #EMPTY_MAP
     * @since 1.5
     */
    static Map!(K,V) emptyMap(K,V)() {
        return new EmptyMap!(K,V)();
    }

    /**
     * Returns an empty navigable set (immutable).  This set is serializable.
     *
     * <p>This example illustrates the type-safe way to obtain an empty
     * navigable set:
     * <pre> {@code
     *     NavigableSet!(string) s = Collections.emptyNavigableSet();
     * }</pre>
     *
     * @implNote Implementations of this method need not
     * create a separate {@code NavigableSet} object for each call.
     *
     * @param <E> type of elements, if there were any, in the set
     * @return the empty navigable set
     * @since 1.8
     */
    static NavigableSet!(E) emptyNavigableSet(E)() {
        return new EmptyNavigableSet!(E)();
    }
    

    // Singleton collections

    /**
     * Returns an immutable set containing only the specified object.
     * The returned set is serializable.
     *
     * @param  !(T) the class of the objects in the set
     * @param o the sole object to be stored in the returned set.
     * @return an immutable set containing only the specified object.
     */
    static Set!T singleton(T)(T o) {
        return new SingletonSet!T(o);
    }
    

    /**
     * Returns an immutable list containing only the specified object.
     * The returned list is serializable.
     *
     * @param  !(T) the class of the objects in the list
     * @param o the sole object to be stored in the returned list.
     * @return an immutable list containing only the specified object.
     * @since 1.3
     */
    static List!T singletonList(T)(T o) {
        return new SingletonList!T(o);
    }

    static List!T emptyList(T)()
    {
        return new EmptyList!T();
    }
    
}

/**
* @serial include
*/
private class EmptyMap(K,V) : AbstractMap!(K,V) {
    // private enum long serialVersionUID = 6428348081105594320L;

    override
    int size()                          {return 0;}

    override
    bool isEmpty()                   {return true;}

    override
    bool containsKey(K key)     {return false;}

    // override
    // bool containsValue(V value) {return false;}

    override
    V get(K key)                   {return V.init;}

    override K[] keySet() { return null; }
    override V[] values() { return null; }
    // Collection!(V) values()              {return emptySet();}
    // Set!(MapEntry!(K,V)) entrySet()      {return emptySet();}

    override
    bool opEquals(Object o) {
        return (typeid(o) == typeid(Map!(K,V))) && (cast(Map!(K,V))o).isEmpty();
    }

    override
    size_t toHash()                      {return 0;}

    // Override default methods in Map
    override
    V getOrDefault(K k, V defaultValue) {
        return defaultValue;
    }

    override int opApply(scope int delegate(ref K, ref V) dg) {
        return 0;
    }

    // override
    // void replaceAll(BiFunction!(K, V, V) function) {
    //     Objects.requireNonNull(function);
    // }

    // override
    // V putIfAbsent(K key, V value) {
    //     throw new UnsupportedOperationException();
    // }

    // override
    // bool remove(Object key, Object value) {
    //     throw new UnsupportedOperationException();
    // }

    // override
    // bool replace(K key, V oldValue, V newValue) {
    //     throw new UnsupportedOperationException();
    // }

    // override
    // V replace(K key, V value) {
    //     throw new UnsupportedOperationException();
    // }

    // override
    // V computeIfAbsent(K key,
    //         Function!(K, V) mappingFunction) {
    //     throw new UnsupportedOperationException();
    // }

    // override
    // V computeIfPresent(K key,
    //         BiFunction!(K, V, V) remappingFunction) {
    //     throw new UnsupportedOperationException();
    // }

    // override
    // V compute(K key,
    //         BiFunction!(K, V, V) remappingFunction) {
    //     throw new UnsupportedOperationException();
    // }

    // override
    // V merge(K key, V value,
    //         BiFunction!(V, V, V) remappingFunction) {
    //     throw new UnsupportedOperationException();
    // }

    // // Preserves singleton property
    // private Object readResolve() {
    //     return EMPTY_MAP;
    // }
}


/**
* @serial include
*/
private static class SingletonSet(E) : AbstractSet!E
{
    // private enum long serialVersionUID = 3193687207550431679L;
    // alias remove = AbstractList.remove; 

    private E element;

    this(E e) {element = e;}

    // Iterator!E iterator() {
    //     return singletonIterator(element);
    // }
    bool remove(E o)
    {
        return true;
    }
    override
    int size() {return 1;}

    bool contains(E)(E o) {return o == element;}

    override
    int opApply(scope int delegate(ref E) dg)
    {
        dg(element);
        return 0;
    }

    // Override default methods for Collection
    // override
    // void forEach(Consumer<E> action) {
    //     action.accept(element);
    // }

    // override
    // Spliterator<E> spliterator() {
    //     return singletonSpliterator(element);
    // }

    // override
    // bool removeIf(Predicate<E> filter) {
    //     throw new UnsupportedOperationException();
    // }
}


/**
* @serial include
*/
private static class SingletonList(E)  : AbstractList!E    {

    // private enum long serialVersionUID = 3093736618740652951L;

    private E element;

    this(E obj)                {element = obj;}

    // Iterator!E iterator() {
    //     return singletonIterator(element);
    // }

    override int size() {return 1;}

    override bool contains(E obj) {
        static if(is(E == class))
            return cast(Object)obj == cast(Object)element;
        else
            return element == obj;
        }

    override E get(int index) {
        if (index != 0)
            throw new IndexOutOfBoundsException("Index: " ~ index.to!string  ~ ", Size: 1");
        return element;
    }

    // Override default methods for Collection
    override
    int opApply(scope int delegate(ref E) dg)
    {
        dg(element);
        return 0;
    }

    // override
    // boole removeIf(Predicate!E filter) {
    //     throw new UnsupportedOperationException();
    // }
    // override
    // void replaceAll(UnaryOperator!E operator) {
    //     throw new UnsupportedOperationException();
    // }
    // override
    // void sort(Comparator!(E) c) {
    // }
    // override
    // Spliterator!E spliterator() {
    //     return singletonSpliterator(element);
    // }
}


/**
* @serial include
*/
private class UnmodifiableCollection(E) : Collection!(E) {
    // private static final long serialVersionUID = 1820017752578914078L;

    protected Collection!(E) c;

    this(Collection!(E) c) {
        if (c is null)
            throw new NullPointerException();
        this.c = c;
    }

    int size()                   {return c.size();}
    bool isEmpty()            {return c.isEmpty();}
    bool contains(E o)   {return c.contains(o);}
    E[] toArray()           {return c.toArray();}
    // !(T) T[] toArray(T[] a)       {return c.toArray(a);}
    override string toString()            {return c.toString();}
    
    override size_t toHash() @trusted nothrow { return super.toHash(); }

    // Iterator!(E) iterator() {
    //     return new Iterator!(E)() {
    //         private final Iterator!(E) i = c.iterator();

    //         bool hasNext() {return i.hasNext();}
    //         E next()          {return i.next();}
    //         void remove() {
    //             throw new UnsupportedOperationException();
    //         }
    //         override
    //         void forEachRemaining(Consumer<E> action) {
    //             // Use backing collection version
    //             i.forEachRemaining(action);
    //         }
    //     };
    // }

    bool add(E e) {
        throw new UnsupportedOperationException();
    }
    bool remove(E o) {
        throw new UnsupportedOperationException();
    }

    bool containsAll(Collection!(E) coll) {
        return c.containsAll(coll);
    }
    bool addAll(Collection!(E) coll) {
        throw new UnsupportedOperationException();
    }
    bool removeAll(Collection!(E) coll) {
        throw new UnsupportedOperationException();
    }
    bool retainAll(Collection!(E) coll) {
        throw new UnsupportedOperationException();
    }
    void clear() {
        throw new UnsupportedOperationException();
    }

    // Override default methods in Collection
    // override
    // void forEach(Consumer!(E) action) {
    //     c.forEach(action);
    // }
    int opApply(scope int delegate(ref E) dg) {
        int r = 0;
        foreach(E e; c) {
            r = dg(e);
            if(r != 0) return r;
        }
        return r;
    }

    // override
    // bool removeIf(Predicate!(E) filter) {
    //     throw new UnsupportedOperationException();
    // }
    
    // override
    // Spliterator!(E) spliterator() {
    //     return (Spliterator!(E))c.spliterator();
    // }
    
    // override
    // Stream!(E) stream() {
    //     return (Stream!(E))c.stream();
    // }
    
    // override
    // Stream!(E) parallelStream() {
    //     return (Stream!(E))c.parallelStream();
    // }
}

/**
* @serial include
*/
private class UnmodifiableSet(E) : UnmodifiableCollection!(E), Set!(E) {
    // private static final long serialVersionUID = -9215047833775013803L;

    this(Set!(E) s)     {super(s);}
    override bool opEquals(Object o) {return o is this || c == o;}
    override size_t toHash() @trusted nothrow           { return c.toHash();}
}

/**
* A singleton empty unmodifiable navigable set used for
* {@link #emptyNavigableSet()}.
*
* @param !(E) type of elements, if there were any, and bounds
*/
private class EmptyNavigableSet(E) : UnmodifiableNavigableSet!(E) {
    // private static final long serialVersionUID = -6291252904449939134L;

    this() {
        super(new TreeSet!(E)());
    }

    // private Object readResolve()        { return EMPTY_NAVIGABLE_SET; }
}

/**
* @serial include
*/
private class UnmodifiableSortedSet(E) : UnmodifiableSet!(E), SortedSet!(E) {
        // private static final long serialVersionUID = -4929149591599911165L;
    private SortedSet!(E) ss;

    this(SortedSet!(E) s) {super(s); ss = s;}

    // Comparator<E> comparator() {return ss.comparator();}

    SortedSet!(E) subSet(E fromElement, E toElement) {
        return new UnmodifiableSortedSet!(E)(ss.subSet(fromElement,toElement));
    }
    SortedSet!(E) headSet(E toElement) {
        return new UnmodifiableSortedSet!(E)(ss.headSet(toElement));
    }
    SortedSet!(E) tailSet(E fromElement) {
        return new UnmodifiableSortedSet!(E)(ss.tailSet(fromElement));
    }

    E first()                   {return ss.first();}
    E last()                    {return ss.last();}
}


/**
* Wraps a navigable set and disables all of the mutative operations.
*
* @param !(E) type of elements
* @serial include
*/
private class UnmodifiableNavigableSet(E) : 
    UnmodifiableSortedSet!(E), NavigableSet!(E) {

    /**
    * The instance we are protecting.
    */
    private NavigableSet!(E) ns;

    this(NavigableSet!(E) s)         {super(s); ns = s;}

    E lower(E e)                             { return ns.lower(e); }
    E floor(E e)                             { return ns.floor(e); }
    E ceiling(E e)                         { return ns.ceiling(e); }
    E higher(E e)                           { return ns.higher(e); }
    E pollFirst()     { throw new UnsupportedOperationException(); }
    E pollLast()      { throw new UnsupportedOperationException(); }
    // NavigableSet!(E) descendingSet()
    //             { return new UnmodifiableNavigableSet!(E)(ns.descendingSet()); }
    // Iterator!(E) descendingIterator()
    //                                     { return descendingSet().iterator(); }

    NavigableSet!(E) subSet(E fromElement, bool fromInclusive, E toElement, bool toInclusive) {
        return new UnmodifiableNavigableSet!(E)(
            ns.subSet(fromElement, fromInclusive, toElement, toInclusive));
    }

    NavigableSet!(E) headSet(E toElement, bool inclusive) {
        return new UnmodifiableNavigableSet!(E)(
            ns.headSet(toElement, inclusive));
    }

    NavigableSet!(E) tailSet(E fromElement, bool inclusive) {
        return new UnmodifiableNavigableSet!(E)(
            ns.tailSet(fromElement, inclusive));
    }

    override SortedSet!(E) subSet(E fromElement, E toElement) {
        return new UnmodifiableSortedSet!(E)(ss.subSet(fromElement,toElement));
    }
    override SortedSet!(E) headSet(E toElement) {
        return new UnmodifiableSortedSet!(E)(ss.headSet(toElement));
    }
    override SortedSet!(E) tailSet(E fromElement) {
        return new UnmodifiableSortedSet!(E)(ss.tailSet(fromElement));
    }

    // alias subSet = UnmodifiableSortedSet!(E).subSet;
    // alias headSet = UnmodifiableSortedSet!(E).headSet;
    // alias tailSet = UnmodifiableSortedSet!(E).tailSet;

}
