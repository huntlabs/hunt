module hunt.container.Collections;


import hunt.container.AbstractList;
import hunt.container.AbstractMap;
import hunt.container.AbstractSet;
import hunt.container.Enumeration;
import hunt.container.List;
import hunt.container.Map;
import hunt.container.Set;

import hunt.util.exception;

import std.conv;
import std.range;

/**
*/
class Collections {
    // Suppresses default constructor, ensuring non-instantiability.

    static this()
    {
    }

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
    static bool eq(Object o1, Object o2) {
        return o1 is null ? o2 is null : o1.opEquals(o2);
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
    // static List!T singletonList(T)(T o) {
    //     return new SingletonList!T(o);
    // }


    /**
     * Returns an empty map (immutable).  This map is serializable.
     *
     * !(p)This example illustrates the type-safe way to obtain an empty map:
     * !(pre)
     *     Map&lt;String, Date&gt; s = Collections.emptyMap();
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
     * @serial include
     */
    private static class EmptyMap(K,V)
        : AbstractMap!(K,V)
    {
        private enum long serialVersionUID = 6428348081105594320L;

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
        // Set!(Map.Entry!(K,V)) entrySet()      {return emptySet();}

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

        override
        int opApply(scope int delegate(ref K, ref V) dg)
        {
            return 0;
        }

        // override
        // void replaceAll(BiFunction!(? super K, ? super V, ? extends V) function) {
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
        //         Function!(? super K, ? extends V) mappingFunction) {
        //     throw new UnsupportedOperationException();
        // }

        // override
        // V computeIfPresent(K key,
        //         BiFunction!(? super K, ? super V, ? extends V) remappingFunction) {
        //     throw new UnsupportedOperationException();
        // }

        // override
        // V compute(K key,
        //         BiFunction!(? super K, ? super V, ? extends V) remappingFunction) {
        //     throw new UnsupportedOperationException();
        // }

        // override
        // V merge(K key, V value,
        //         BiFunction!(? super V, ? super V, ? extends V) remappingFunction) {
        //     throw new UnsupportedOperationException();
        // }

        // // Preserves singleton property
        // private Object readResolve() {
        //     return EMPTY_MAP;
        // }
    }

    // Singleton collections

    /**
     * Returns an immutable set containing only the specified object.
     * The returned set is serializable.
     *
     * @param  <T> the class of the objects in the set
     * @param o the sole object to be stored in the returned set.
     * @return an immutable set containing only the specified object.
     */
    static Set!T singleton(T)(T o) {
        return new SingletonSet!T(o);
    }
    
    /**
     * @serial include
     */
    private static class SingletonSet(E) : AbstractSet!E
    {
        private enum long serialVersionUID = 3193687207550431679L;

        private E element;

        this(E e) {element = e;}

        // Iterator!E iterator() {
        //     return singletonIterator(element);
        // }

        override
        int size() {return 1;}

        bool contains(Object o) {return eq(o, element);}

        // override
        int opApply(scope int delegate(ref E) dg)
        {
            dg(element);
            return 0;
        }

        // Override default methods for Collection
        // override
        // void forEach(Consumer<? super E> action) {
        //     action.accept(element);
        // }

        // override
        // Spliterator<E> spliterator() {
        //     return singletonSpliterator(element);
        // }

        // override
        // bool removeIf(Predicate<? super E> filter) {
        //     throw new UnsupportedOperationException();
        // }
    }

    /**
     * Returns an immutable list containing only the specified object.
     * The returned list is serializable.
     *
     * @param  <T> the class of the objects in the list
     * @param o the sole object to be stored in the returned list.
     * @return an immutable list containing only the specified object.
     * @since 1.3
     */
    static List!T singletonList(T)(T o) {
        return new SingletonList!T(o);
    }

    /**
     * @serial include
     */
    private static class SingletonList(E)  : AbstractList!E
        // implements RandomAccess, Serializable
        {

        private enum long serialVersionUID = 3093736618740652951L;

        private E element;

        this(E obj)                {element = obj;}

        // Iterator!E iterator() {
        //     return singletonIterator(element);
        // }

        override int size() {return 1;}

        override bool contains(E obj) {return eq(obj, element);}

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
        // void sort(Comparator!(? super E) c) {
        // }
        // override
        // Spliterator!E spliterator() {
        //     return singletonSpliterator(element);
        // }
    }
}