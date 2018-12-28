module hunt.container.TreeMap;

import hunt.container.AbstractCollection;
import hunt.container.AbstractMap;
import hunt.container.AbstractSet;
import hunt.container.Collection;
import hunt.container.Iterator;
import hunt.container.Map;
import hunt.container.NavigableMap;
import hunt.container.NavigableSet;
import hunt.container.Set;
import hunt.container.SortedMap;
import hunt.container.SortedSet;

import hunt.lang.common;
import hunt.lang.exception;
import hunt.lang.Object;
import hunt.util.Comparator;
import hunt.util.functional;
import hunt.util.Spliterator;

import std.algorithm;
import std.conv;
import std.exception;
import std.math;
import std.range;
import std.traits;


version (HUNT_DEBUG) import hunt.logging.ConsoleLogger;

// Red-black mechanics

private enum bool RED   = false;
private enum bool BLACK = true;


/**
 * A Red-Black tree based {@link NavigableMap} implementation.
 * The map is sorted according to the {@linkplain Comparable natural
 * ordering} of its keys, or by a {@link Comparator} provided at map
 * creation time, depending on which constructor is used.
 *
 * <p>This implementation provides guaranteed log(n) time cost for the
 * {@code containsKey}, {@code get}, {@code put} and {@code remove}
 * operations.  Algorithms are adaptations of those in Cormen, Leiserson, and
 * Rivest's <em>Introduction to Algorithms</em>.
 *
 * <p>Note that the ordering maintained by a tree map, like any sorted map, and
 * whether or not an explicit comparator is provided, must be <em>consistent
 * with {@code equals}</em> if this sorted map is to correctly implement the
 * {@code Map} interface.  (See {@code Comparable} or {@code Comparator} for a
 * precise definition of <em>consistent with equals</em>.)  This is so because
 * the {@code Map} interface is defined in terms of the {@code equals}
 * operation, but a sorted map performs all key comparisons using its {@code
 * compareTo} (or {@code compare}) method, so two keys that are deemed equal by
 * this method are, from the standpoint of the sorted map, equal.  The behavior
 * of a sorted map <em>is</em> well-defined even if its ordering is
 * inconsistent with {@code equals}; it just fails to obey the general contract
 * of the {@code Map} interface.
 *
 * <p><strong>Note that this implementation is not synchronized.</strong>
 * If multiple threads access a map concurrently, and at least one of the
 * threads modifies the map structurally, it <em>must</em> be synchronized
 * externally.  (A structural modification is any operation that adds or
 * deletes one or more mappings; merely changing the value associated
 * with an existing key is not a structural modification.)  This is
 * typically accomplished by synchronizing on some object that naturally
 * encapsulates the map.
 * If no such object exists, the map should be "wrapped" using the
 * {@link Collections#synchronizedSortedMap Collections.synchronizedSortedMap}
 * method.  This is best done at creation time, to prevent accidental
 * unsynchronized access to the map: <pre>
 *   SortedMap m = Collections.synchronizedSortedMap(new TreeMap(...));</pre>
 *
 * <p>The iterators returned by the {@code iterator} method of the collections
 * returned by all of this class's "collection view methods" are
 * <em>fail-fast</em>: if the map is structurally modified at any time after
 * the iterator is created, in any way except through the iterator's own
 * {@code remove} method, the iterator will throw a {@link
 * ConcurrentModificationException}.  Thus, in the face of concurrent
 * modification, the iterator fails quickly and cleanly, rather than risking
 * arbitrary, non-deterministic behavior at an undetermined time in the future.
 *
 * <p>Note that the fail-fast behavior of an iterator cannot be guaranteed
 * as it is, generally speaking, impossible to make any hard guarantees in the
 * presence of unsynchronized concurrent modification.  Fail-fast iterators
 * throw {@code ConcurrentModificationException} on a best-effort basis.
 * Therefore, it would be wrong to write a program that depended on this
 * exception for its correctness:   <em>the fail-fast behavior of iterators
 * should be used only to detect bugs.</em>
 *
 * <p>All {@code MapEntry} pairs returned by methods in this class
 * and its views represent snapshots of mappings at the time they were
 * produced. They do <strong>not</strong> support the {@code Entry.setValue}
 * method. (Note however that it is possible to change mappings in the
 * associated map using {@code put}.)
 *
 * <p>This class is a member of the
 * <a href="{@docRoot}/../technotes/guides/collections/index.html">
 * Java Collections Framework</a>.
 *
 * @param !K the type of keys maintained by this map
 * @param !V the type of mapped values
 *
 * @author  Josh Bloch and Doug Lea
 * @see Map
 * @see HashMap
 * @see Hashtable
 * @see Comparable
 * @see Comparator
 * @see Collection
 * @since 1.2
 */

class TreeMap(K,V) : AbstractMap!(K,V), NavigableMap!(K,V) { //, Cloneable, java.io.Serializable

    /**
     * The comparator used to maintain order in this tree map, or
     * null if it uses the natural ordering of its keys.
     *
     * @serial
     */
    private Comparator!K _comparator;

    private TreeMapEntry!(K,V) root;

    /**
     * The number of entries in the tree
     */
    // private int _size = 0;

    /**
     * The number of structural modifications to the tree.
     */
    private int modCount = 0;

    /**
     * Constructs a new, empty tree map, using the natural ordering of its
     * keys.  All keys inserted into the map must implement the {@link
     * Comparable} interface.  Furthermore, all such keys must be
     * <em>mutually comparable</em>: {@code k1.compareTo(k2)} must not throw
     * a {@code ClassCastException} for any keys {@code k1} and
     * {@code k2} in the map.  If the user attempts to put a key into the
     * map that violates this constraint (for example, the user attempts to
     * put a string key into a map whose keys are integers), the
     * {@code put(Object key, Object value)} call will throw a
     * {@code ClassCastException}.
     */
    this() {
        _comparator = null;
    }

    /**
     * Constructs a new, empty tree map, ordered according to the given
     * comparator.  All keys inserted into the map must be <em>mutually
     * comparable</em> by the given comparator: {@code comparator.compare(k1,
     * k2)} must not throw a {@code ClassCastException} for any keys
     * {@code k1} and {@code k2} in the map.  If the user attempts to put
     * a key into the map that violates this constraint, the {@code put(Object
     * key, Object value)} call will throw a
     * {@code ClassCastException}.
     *
     * @param comparator the comparator that will be used to order this map.
     *        If {@code null}, the {@linkplain Comparable natural
     *        ordering} of the keys will be used.
     */
    this(Comparator!K comparator) {
        this._comparator = comparator;
    }

    /**
     * Constructs a new tree map containing the same mappings as the given
     * map, ordered according to the <em>natural ordering</em> of its keys.
     * All keys inserted into the new map must implement the {@link
     * Comparable} interface.  Furthermore, all such keys must be
     * <em>mutually comparable</em>: {@code k1.compareTo(k2)} must not throw
     * a {@code ClassCastException} for any keys {@code k1} and
     * {@code k2} in the map.  This method runs in n*log(n) time.
     *
     * @param  m the map whose mappings are to be placed in this map
     * @throws ClassCastException if the keys in m are not {@link Comparable},
     *         or are not mutually comparable
     * @throws NullPointerException if the specified map is null
     */
    this(Map!(K, V) m) {
        _comparator = null;
        putAll(m);
    }

    /**
     * Constructs a new tree map containing the same mappings and
     * using the same ordering as the specified sorted map.  This
     * method runs in linear time.
     *
     * @param  m the sorted map whose mappings are to be placed in this map,
     *         and whose comparator is to be used to sort this map
     * @throws NullPointerException if the specified map is null
     */
    // this(SortedMap!(K, V) m) {
    //     _comparator = m.comparator();
    //     try {
    //         buildFromSorted(m.size(), m.entrySet().iterator(), null, null);
    //     } catch (IOException cannotHappen) {
    //     } catch (ClassNotFoundException cannotHappen) {
    //     }
    // }


    // Query Operations

    /**
     * Returns the number of key-value mappings in this map.
     *
     * @return the number of key-value mappings in this map
     */
    // override int size() {
    //     return _size;
    // }

    /**
     * Returns {@code true} if this map contains a mapping for the specified
     * key.
     *
     * @param key key whose presence in this map is to be tested
     * @return {@code true} if this map contains a mapping for the
     *         specified key
     * @throws ClassCastException if the specified key cannot be compared
     *         with the keys currently in the map
     * @throws NullPointerException if the specified key is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     */
    override bool containsKey(K key) {
        return getEntry(key) !is null;
    }

    /**
     * Returns {@code true} if this map maps one or more keys to the
     * specified value.  More formally, returns {@code true} if and only if
     * this map contains at least one mapping to a value {@code v} such
     * that {@code (value is null ? v is null : value.equals(v))}.  This
     * operation will probably require time linear in the map size for
     * most implementations.
     *
     * @param value value whose presence in this map is to be tested
     * @return {@code true} if a mapping to {@code value} exists;
     *         {@code false} otherwise
     * @since 1.2
     */
    override bool containsValue(V value) {
        for (TreeMapEntry!(K,V) e = getFirstEntry(); e !is null; e = successor(e))
            if (valEquals(value, e.value))
                return true;
        return false;
    }

    /**
     * Returns the value to which the specified key is mapped,
     * or {@code null} if this map contains no mapping for the key.
     *
     * <p>More formally, if this map contains a mapping from a key
     * {@code k} to a value {@code v} such that {@code key} compares
     * equal to {@code k} according to the map's ordering, then this
     * method returns {@code v}; otherwise it returns {@code null}.
     * (There can be at most one such mapping.)
     *
     * <p>A return value of {@code null} does not <em>necessarily</em>
     * indicate that the map contains no mapping for the key; it's also
     * possible that the map explicitly maps the key to {@code null}.
     * The {@link #containsKey containsKey} operation may be used to
     * distinguish these two cases.
     *
     * @throws ClassCastException if the specified key cannot be compared
     *         with the keys currently in the map
     * @throws NullPointerException if the specified key is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     */
    override V get(K key) {
        TreeMapEntry!(K,V) p = getEntry(key);
        return (p is null ? null : p.value);
    }

    Comparator!K comparator() {
        return _comparator;
    }

    /**
     * @throws NoSuchElementException {@inheritDoc}
     */
    K firstKey() {
        return key(getFirstEntry());
    }

    /**
     * @throws NoSuchElementException {@inheritDoc}
     */
    K lastKey() {
        return key(getLastEntry());
    }

    /**
     * Copies all of the mappings from the specified map to this map.
     * These mappings replace any mappings that this map had for any
     * of the keys currently in the specified map.
     *
     * @param  map mappings to be stored in this map
     * @throws ClassCastException if the class of a key or value in
     *         the specified map prevents it from being stored in this map
     * @throws NullPointerException if the specified map is null or
     *         the specified map contains a null key and this map does not
     *         permit null keys
     */
    override void putAll(Map!(K, V) map) {
        int mapSize = map.size();
        SortedMap!(K, V) sortedMap = cast(SortedMap!(K, V)) map;
        if (_size==0 && mapSize !is 0 && sortedMap !is null) {
            Comparator!K c = sortedMap.comparator();
            if (c == _comparator) {
                ++modCount;
                implementationMissing(false);
                // try {
                //     buildFromSorted(mapSize, map, //.entrySet().iterator(),
                //                     null, null);
                // } catch (IOException cannotHappen) {
                // } 
                // catch (ClassNotFoundException cannotHappen) {
                // }
                return;
            }
        }
        super.putAll(map);
    }

    /**
     * Returns this map's entry for the given key, or {@code null} if the map
     * does not contain an entry for the key.
     *
     * @return this map's entry for the given key, or {@code null} if the map
     *         does not contain an entry for the key
     * @throws ClassCastException if the specified key cannot be compared
     *         with the keys currently in the map
     * @throws NullPointerException if the specified key is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     */
    final TreeMapEntry!(K,V) getEntry(K key) {
        // Offload comparator-based version for sake of performance
        if (_comparator !is null)
            return getEntryUsingComparator(key);
        static if(is(T == class))
        {
            if (key is null)
                throw new NullPointerException();
        }
        K k = key;
        TreeMapEntry!(K,V) p = root;
        while (p !is null) {
            // static if(isNumeric!(K))
            //     int cp = std.math.cmp(cast(float)k, cast(float)p.key);
            // else
            //     int cp = std.algorithm.cmp(k, p.key);
            int cp = compare(k, p.key);

            if (cp < 0)
                p = p.left;
            else if (cp > 0)
                p = p.right;
            else
                return p;
        }
        return null;
    }

    /**
     * Version of getEntry using comparator. Split off from getEntry
     * for performance. (This is not worth doing for most methods,
     * that are less dependent on comparator performance, but is
     * worthwhile here.)
     */
    final TreeMapEntry!(K,V) getEntryUsingComparator(K key) {
        K k = key;
        Comparator!K cpr = _comparator;
        if (cpr !is null) {
            TreeMapEntry!(K,V) p = root;
            while (p !is null) {
                int cmp = cpr.compare(k, p.key);
                if (cmp < 0)
                    p = p.left;
                else if (cmp > 0)
                    p = p.right;
                else
                    return p;
            }
        }
        return null;
    }

    /**
     * Gets the entry corresponding to the specified key; if no such entry
     * exists, returns the entry for the least key greater than the specified
     * key; if no such entry exists (i.e., the greatest key in the Tree is less
     * than the specified key), returns {@code null}.
     */
    final TreeMapEntry!(K,V) getCeilingEntry(K key) {
        TreeMapEntry!(K,V) p = root;
        while (p !is null) {
            int cmp = compare(key, p.key);
            if (cmp < 0) {
                if (p.left !is null)
                    p = p.left;
                else
                    return p;
            } else if (cmp > 0) {
                if (p.right !is null) {
                    p = p.right;
                } else {
                    TreeMapEntry!(K,V) parent = p.parent;
                    TreeMapEntry!(K,V) ch = p;
                    while (parent !is null && ch == parent.right) {
                        ch = parent;
                        parent = parent.parent;
                    }
                    return parent;
                }
            } else
                return p;
        }
        return null;
    }

    /**
     * Gets the entry corresponding to the specified key; if no such entry
     * exists, returns the entry for the greatest key less than the specified
     * key; if no such entry exists, returns {@code null}.
     */
    final TreeMapEntry!(K,V) getFloorEntry(K key) {
        TreeMapEntry!(K,V) p = root;
        while (p !is null) {
            int cmp = compare(key, p.key);
            if (cmp > 0) {
                if (p.right !is null)
                    p = p.right;
                else
                    return p;
            } else if (cmp < 0) {
                if (p.left !is null) {
                    p = p.left;
                } else {
                    TreeMapEntry!(K,V) parent = p.parent;
                    TreeMapEntry!(K,V) ch = p;
                    while (parent !is null && ch == parent.left) {
                        ch = parent;
                        parent = parent.parent;
                    }
                    return parent;
                }
            } else
                return p;

        }
        return null;
    }

    /**
     * Gets the entry for the least key greater than the specified
     * key; if no such entry exists, returns the entry for the least
     * key greater than the specified key; if no such entry exists
     * returns {@code null}.
     */
    final TreeMapEntry!(K,V) getHigherEntry(K key) {
        TreeMapEntry!(K,V) p = root;
        while (p !is null) {
            int cmp = compare(key, p.key);
            if (cmp < 0) {
                if (p.left !is null)
                    p = p.left;
                else
                    return p;
            } else {
                if (p.right !is null) {
                    p = p.right;
                } else {
                    TreeMapEntry!(K,V) parent = p.parent;
                    TreeMapEntry!(K,V) ch = p;
                    while (parent !is null && ch == parent.right) {
                        ch = parent;
                        parent = parent.parent;
                    }
                    return parent;
                }
            }
        }
        return null;
    }

    /**
     * Returns the entry for the greatest key less than the specified key; if
     * no such entry exists (i.e., the least key in the Tree is greater than
     * the specified key), returns {@code null}.
     */
    final TreeMapEntry!(K,V) getLowerEntry(K key) {
        TreeMapEntry!(K,V) p = root;
        while (p !is null) {
            int cmp = compare(key, p.key);
            if (cmp > 0) {
                if (p.right !is null)
                    p = p.right;
                else
                    return p;
            } else {
                if (p.left !is null) {
                    p = p.left;
                } else {
                    TreeMapEntry!(K,V) parent = p.parent;
                    TreeMapEntry!(K,V) ch = p;
                    while (parent !is null && ch == parent.left) {
                        ch = parent;
                        parent = parent.parent;
                    }
                    return parent;
                }
            }
        }
        return null;
    }

    /**
     * Associates the specified value with the specified key in this map.
     * If the map previously contained a mapping for the key, the old
     * value is replaced.
     *
     * @param key key with which the specified value is to be associated
     * @param value value to be associated with the specified key
     *
     * @return the previous value associated with {@code key}, or
     *         {@code null} if there was no mapping for {@code key}.
     *         (A {@code null} return can also indicate that the map
     *         previously associated {@code null} with {@code key}.)
     * @throws ClassCastException if the specified key cannot be compared
     *         with the keys currently in the map
     * @throws NullPointerException if the specified key is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     */
    override V put(K key, V value) {
        TreeMapEntry!(K,V) t = root;
        if (t is null) {
            // compare(key, key); // type (and possibly null) check

            root = new TreeMapEntry!(K,V)(key, value, null);
            _size = 1;
            modCount++;
            return null;
        }
        int _cmp;
        TreeMapEntry!(K,V) parent;
        // split comparator and comparable paths
        Comparator!K cpr = _comparator;
        if (cpr !is null) {
            do {
                parent = t;
                _cmp = cpr.compare(key, t.key);
                if (_cmp < 0)
                    t = t.left;
                else if (_cmp > 0)
                    t = t.right;
                else
                    return t.setValue(value);
            } while (t !is null);
        }
        else {
            // if (key is null)
            //     throw new NullPointerException();
            // Comparable!K k = cast(Comparable!K) key;
            K k = key;
            do {
                parent = t;
                // _cmp = k.compareTo(t.key);
                
                // static if(isNumeric!(K))
                //     _cmp = std.math.cmp(cast(float)k, cast(float)t.key);
                // else
                //     _cmp = std.algorithm.cmp(k, t.key);
                _cmp = compare(k, t.key);

                if (_cmp < 0)
                    t = t.left;
                else if (_cmp > 0)
                    t = t.right;
                else
                    return t.setValue(value);
            } while (t !is null);
        }
        TreeMapEntry!(K,V) e = new TreeMapEntry!(K,V)(key, value, parent);
        if (_cmp < 0)
            parent.left = e;
        else
            parent.right = e;
        fixAfterInsertion(e);
        _size++;
        modCount++;
        return null;
    }

    /**
     * Removes the mapping for this key from this TreeMap if present.
     *
     * @param  key key for which mapping should be removed
     * @return the previous value associated with {@code key}, or
     *         {@code null} if there was no mapping for {@code key}.
     *         (A {@code null} return can also indicate that the map
     *         previously associated {@code null} with {@code key}.)
     * @throws ClassCastException if the specified key cannot be compared
     *         with the keys currently in the map
     * @throws NullPointerException if the specified key is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     */
    override V remove(K key) {
        TreeMapEntry!(K,V) p = getEntry(key);
        if (p is null)
            return null;

        V oldValue = p.value;
        deleteEntry(p);
        return oldValue;
    }

    /**
     * Removes all of the mappings from this map.
     * The map will be empty after this call returns.
     */
    override void clear() {
        modCount++;
        _size = 0;
        root = null;
    }

    /**
     * Returns a shallow copy of this {@code TreeMap} instance. (The keys and
     * values themselves are not cloned.)
     *
     * @return a shallow copy of this map
     */
    // Object clone() {
    //     TreeMap<?,?> clone;
    //     try {
    //         clone = (TreeMap<?,?>) super.clone();
    //     } catch (CloneNotSupportedException e) {
    //         throw new InternalError(e);
    //     }

    //     // Put clone into "virgin" state (except for comparator)
    //     clone.root = null;
    //     clone.size = 0;
    //     clone.modCount = 0;
    //     clone.entrySet = null;
    //     clone._navigableKeySet = null;
    //     clone._descendingMap = null;

    //     // Initialize clone with our mappings
    //     try {
    //         clone.buildFromSorted(size, entrySet().iterator(), null, null);
    //     } catch (java.io.IOException cannotHappen) {
    //     } catch (ClassNotFoundException cannotHappen) {
    //     }

    //     return clone;
    // }

    // NavigableMap API methods

    /**
     * @since 1.6
     */
    MapEntry!(K,V) firstEntry() {
        return exportEntry!(K,V)(getFirstEntry());
    }

    /**
     * @since 1.6
     */
    MapEntry!(K,V) lastEntry() {
        return exportEntry!(K,V)(getLastEntry());
    }

    /**
     * @since 1.6
     */
    MapEntry!(K,V) pollFirstEntry() {
        TreeMapEntry!(K,V) p = getFirstEntry();
        MapEntry!(K,V) result = exportEntry!(K,V)(p);
        if (p !is null)
            deleteEntry(p);
        return result;
    }

    /**
     * @since 1.6
     */
    MapEntry!(K,V) pollLastEntry() {
        TreeMapEntry!(K,V) p = getLastEntry();
        MapEntry!(K,V) result = exportEntry!(K,V)(p);
        if (p !is null)
            deleteEntry(p);
        return result;
    }

    /**
     * @throws ClassCastException {@inheritDoc}
     * @throws NullPointerException if the specified key is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     * @since 1.6
     */
    MapEntry!(K,V) lowerEntry(K key) {
        return exportEntry!(K,V)(getLowerEntry(key));
    }

    /**
     * @throws ClassCastException {@inheritDoc}
     * @throws NullPointerException if the specified key is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     * @since 1.6
     */
    K lowerKey(K key) {
        return keyOrNull(getLowerEntry(key));
    }

    /**
     * @throws ClassCastException {@inheritDoc}
     * @throws NullPointerException if the specified key is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     * @since 1.6
     */
    MapEntry!(K,V) floorEntry(K key) {
        return exportEntry!(K,V)(getFloorEntry(key));
    }

    /**
     * @throws ClassCastException {@inheritDoc}
     * @throws NullPointerException if the specified key is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     * @since 1.6
     */
    K floorKey(K key) {
        return keyOrNull(getFloorEntry(key));
    }

    /**
     * @throws ClassCastException {@inheritDoc}
     * @throws NullPointerException if the specified key is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     * @since 1.6
     */
    MapEntry!(K,V) ceilingEntry(K key) {
        return exportEntry!(K,V)(getCeilingEntry(key));
    }

    /**
     * @throws ClassCastException {@inheritDoc}
     * @throws NullPointerException if the specified key is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     * @since 1.6
     */
    K ceilingKey(K key) {
        return keyOrNull(getCeilingEntry(key));
    }

    /**
     * @throws ClassCastException {@inheritDoc}
     * @throws NullPointerException if the specified key is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     * @since 1.6
     */
    MapEntry!(K,V) higherEntry(K key) {
        return exportEntry!(K,V)(getHigherEntry(key));
    }

    /**
     * @throws ClassCastException {@inheritDoc}
     * @throws NullPointerException if the specified key is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     * @since 1.6
     */
    K higherKey(K key) {
        return keyOrNull(getHigherEntry(key));
    }

    // Views

    /**
     * Fields initialized to contain an instance of the entry set view
     * the first time this view is requested.  Views are stateless, so
     * there's no reason to create more than one.
     */
    // private EntrySet _entrySet;
    // private KeySet!(K,V) _navigableKeySet;
    private NavigableMap!(K,V) _descendingMap;

    /**
     * Returns a {@link Set} view of the keys contained in this map.
     *
     * <p>The set's iterator returns the keys in ascending order.
     * The set's spliterator is
     * <em><a href="Spliterator.html#binding">late-binding</a></em>,
     * <em>fail-fast</em>, and additionally reports {@link Spliterator#SORTED}
     * and {@link Spliterator#ORDERED} with an encounter order that is ascending
     * key order.  The spliterator's comparator (see
     * {@link java.util.Spliterator#getComparator()}) is {@code null} if
     * the tree map's comparator (see {@link #comparator()}) is {@code null}.
     * Otherwise, the spliterator's comparator is the same as or imposes the
     * same total ordering as the tree map's comparator.
     *
     * <p>The set is backed by the map, so changes to the map are
     * reflected in the set, and vice-versa.  If the map is modified
     * while an iteration over the set is in progress (except through
     * the iterator's own {@code remove} operation), the results of
     * the iteration are undefined.  The set supports element removal,
     * which removes the corresponding mapping from the map, via the
     * {@code Iterator.remove}, {@code Set.remove},
     * {@code removeAll}, {@code retainAll}, and {@code clear}
     * operations.  It does not support the {@code add} or {@code addAll}
     * operations.
     */
    // Set!K keySet() {
    //     return navigableKeySet();
    // }

    /**
     * @since 1.6
     */
    // NavigableSet!K navigableKeySet() {
    //     KeySet!(K, V) nks = _navigableKeySet;
    //     return (nks !is null) ? nks : (_navigableKeySet = new KeySet!(K, V)(this));
    // }

    /**
     * @since 1.6
     */
    // NavigableSet!K descendingKeySet() {
    //     return descendingMap().navigableKeySet();
    // }

    /**
     * Returns a {@link Collection} view of the values contained in this map.
     *
     * <p>The collection's iterator returns the values in ascending order
     * of the corresponding keys. The collection's spliterator is
     * <em><a href="Spliterator.html#binding">late-binding</a></em>,
     * <em>fail-fast</em>, and additionally reports {@link Spliterator#ORDERED}
     * with an encounter order that is ascending order of the corresponding
     * keys.
     *
     * <p>The collection is backed by the map, so changes to the map are
     * reflected in the collection, and vice-versa.  If the map is
     * modified while an iteration over the collection is in progress
     * (except through the iterator's own {@code remove} operation),
     * the results of the iteration are undefined.  The collection
     * supports element removal, which removes the corresponding
     * mapping from the map, via the {@code Iterator.remove},
     * {@code Collection.remove}, {@code removeAll},
     * {@code retainAll} and {@code clear} operations.  It does not
     * support the {@code add} or {@code addAll} operations.
     */
    // Collection!V values() {
    //     Collection!V vs = values;
    //     if (vs is null) {
    //         vs = new Values();
    //         values = vs;
    //     }
    //     return vs;
    // }

    /**
     * Returns a {@link Set} view of the mappings contained in this map.
     *
     * <p>The set's iterator returns the entries in ascending key order. The
     * sets's spliterator is
     * <em><a href="Spliterator.html#binding">late-binding</a></em>,
     * <em>fail-fast</em>, and additionally reports {@link Spliterator#SORTED} and
     * {@link Spliterator#ORDERED} with an encounter order that is ascending key
     * order.
     *
     * <p>The set is backed by the map, so changes to the map are
     * reflected in the set, and vice-versa.  If the map is modified
     * while an iteration over the set is in progress (except through
     * the iterator's own {@code remove} operation, or through the
     * {@code setValue} operation on a map entry returned by the
     * iterator) the results of the iteration are undefined.  The set
     * supports element removal, which removes the corresponding
     * mapping from the map, via the {@code Iterator.remove},
     * {@code Set.remove}, {@code removeAll}, {@code retainAll} and
     * {@code clear} operations.  It does not support the
     * {@code add} or {@code addAll} operations.
     */
    // Set!(MapEntry!(K,V)) entrySet() {
    //     EntrySet es = _entrySet;
    //     return (es !is null) ? es : (_entrySet = new EntrySet());
    // }

    /**
     * @since 1.6
     */
    // NavigableMap!(K, V) descendingMap() {
    //     NavigableMap!(K, V) km = _descendingMap;
    //     return (km !is null) ? km :
    //         (_descendingMap = new DescendingSubMap!(K, V)(this,
    //                                                 true, K.init, true,
    //                                                 true, K.init, true));
    // }

    /**
     * @throws ClassCastException       {@inheritDoc}
     * @throws NullPointerException if {@code fromKey} or {@code toKey} is
     *         null and this map uses natural ordering, or its comparator
     *         does not permit null keys
     * @throws IllegalArgumentException {@inheritDoc}
     * @since 1.6
     */
    NavigableMap!(K,V) subMap(K fromKey, bool fromInclusive,
                                    K toKey,   bool toInclusive) {
        return new AscendingSubMap!(K, V)(this,
                                     false, fromKey, fromInclusive,
                                     false, toKey,   toInclusive);
    }

    /**
     * @throws ClassCastException       {@inheritDoc}
     * @throws NullPointerException if {@code toKey} is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     * @throws IllegalArgumentException {@inheritDoc}
     * @since 1.6
     */
    NavigableMap!(K,V) headMap(K toKey, bool inclusive) {
        return new AscendingSubMap!(K, V)(this,
                                     true,  K.init,  true,
                                     false, toKey, inclusive);
    }

    /**
     * @throws ClassCastException       {@inheritDoc}
     * @throws NullPointerException if {@code fromKey} is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     * @throws IllegalArgumentException {@inheritDoc}
     * @since 1.6
     */
    NavigableMap!(K,V) tailMap(K fromKey, bool inclusive) {
        return new AscendingSubMap!(K, V)(this,
                                     false, fromKey, inclusive,
                                     true,  K.init,    true);
    }

    /**
     * @throws ClassCastException       {@inheritDoc}
     * @throws NullPointerException if {@code fromKey} or {@code toKey} is
     *         null and this map uses natural ordering, or its comparator
     *         does not permit null keys
     * @throws IllegalArgumentException {@inheritDoc}
     */
    SortedMap!(K,V) subMap(K fromKey, K toKey) {
        return subMap(fromKey, true, toKey, false);
    }

    /**
     * @throws ClassCastException       {@inheritDoc}
     * @throws NullPointerException if {@code toKey} is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     * @throws IllegalArgumentException {@inheritDoc}
     */
    SortedMap!(K,V) headMap(K toKey) {
        return headMap(toKey, false);
    }

    /**
     * @throws ClassCastException       {@inheritDoc}
     * @throws NullPointerException if {@code fromKey} is null
     *         and this map uses natural ordering, or its comparator
     *         does not permit null keys
     * @throws IllegalArgumentException {@inheritDoc}
     */
    SortedMap!(K,V) tailMap(K fromKey) {
        return tailMap(fromKey, true);
    }

    override
    bool replace(K key, V oldValue, V newValue) {
        TreeMapEntry!(K,V) p = getEntry(key);
        if (p !is null && oldValue == p.value) {
            p.value = newValue;
            return true;
        }
        return false;
    }

    override
    V replace(K key, V value) {
        TreeMapEntry!(K,V) p = getEntry(key);
        if (p !is null) {
            V oldValue = p.value;
            p.value = value;
            return oldValue;
        }
        return null;
    }

    // override
    // void replaceAll(BiFunction<K, V, ? : V> function) {
    //     Objects.requireNonNull(function);
    //     int expectedModCount = modCount;

    //     for (TreeMapEntry!(K, V) e = getFirstEntry(); e !is null; e = successor(e)) {
    //         e.value = function.apply(e.key, e.value);

    //         if (expectedModCount  !is  modCount) {
    //             throw new ConcurrentModificationException();
    //         }
    //     }
    // }


    // View class support

    override int opApply(scope int delegate(ref K, ref V) dg) {
        if(dg is null)
            throw new NullPointerException();

        int result = 0;
        int expectedModCount = modCount;
        for (TreeMapEntry!(K, V) e = getFirstEntry(); e !is null; e = successor(e)) {
            result = dg(e.key, e.value);
            if(result != 0) return result;
        }

        if (expectedModCount  !is  modCount) 
            throw new ConcurrentModificationException();

        return result;
    }

    
    override int opApply(scope int delegate(MapEntry!(K, V) entry) dg) {
        if(dg is null)
            throw new NullPointerException();

        int result = 0;
        int expectedModCount = modCount;
        for (TreeMapEntry!(K, V) e = getFirstEntry(); e !is null; e = successor(e)) {
            result = dg(e);
            if(result != 0) return result;
        }

        if (expectedModCount  !is  modCount) 
            throw new ConcurrentModificationException();

        return result;
    }
    
    override InputRange!K byKey()
    {
        return new KeyInputRange();
        // throw new NotImplementedException();
    }

    override InputRange!V byValue()
    {
        return new ValueInputRange();
        // throw new NotImplementedException();
    }


    // class Values : AbstractCollection!V {
    //     Iterator!V iterator() {
    //         return new ValueIterator(getFirstEntry());
    //     }

    //     override int size() {
    //         return this.outer.size();
    //     }

    //     override bool contains(V o) {
    //         return this.outer.containsValue(o);
    //     }

    //     bool remove(V o) {
    //         for (TreeMapEntry!(K,V) e = getFirstEntry(); e !is null; e = successor(e)) {
    //             if (valEquals(e.getValue(), o)) {
    //                 deleteEntry(e);
    //                 return true;
    //             }
    //         }
    //         return false;
    //     }

    //     override void clear() {
    //         this.outer.clear();
    //     }

    //     // Spliterator!V spliterator() {
    //     //     return new ValueSpliterator!(K,V)(TreeMap.this, null, null, 0, -1, 0);
    //     // }
    // }

    // class EntrySet : AbstractSet!(MapEntry!(K,V)) {

    //     Iterator!(MapEntry!(K,V)) iterator() {
    //         return new EntryIterator(getFirstEntry());
    //     }

    //     override bool contains(MapEntry!(K,V) entry) {
    //         // if (!(o instanceof MapEntry))
    //         //     return false;
    //         // MapEntry<?,?> entry = (MapEntry<?,?>) o;
    //         V value = entry.getValue();
    //         TreeMapEntry!(K,V) p = getEntry(entry.getKey());
    //         return p !is null && valEquals(p.getValue(), value);
    //     }

    //     bool remove(MapEntry!(K,V) entry) {
    //         // if (!(o instanceof MapEntry))
    //         //     return false;
    //         // MapEntry<?,?> entry = (MapEntry<?,?>) o;
    //         V value = entry.getValue();
    //         TreeMapEntry!(K,V) p = getEntry(entry.getKey());
    //         if (p !is null && valEquals(p.getValue(), value)) {
    //             deleteEntry(p);
    //             return true;
    //         }
    //         return false;
    //     }

    //     override int size() {
    //         return this.outer.size();
    //     }

    //     override void clear() {
    //         this.outer.clear();
    //     }

    //     // Spliterator!(MapEntry!(K,V)) spliterator() {
    //     //     return new EntrySpliterator!(K,V)(this.outer, null, null, 0, -1, 0);
    //     // }
    // }

    /*
     * Unlike Values and EntrySet, the KeySet class is static,
     * delegating to a NavigableMap to allow use by SubMaps, which
     * outweighs the ugliness of needing type-tests for the following
     * Iterator methods that are defined appropriately in main versus
     * submap classes.
     */

    // Iterator!K keyIterator() {
    //     return new KeyIterator(getFirstEntry());
    // }

    // Iterator!K descendingKeyIterator() {
    //     return new DescendingKeyIterator(getLastEntry());
    // }

    // static final class KeySet(E, V) : AbstractSet!E , NavigableSet!E {
    //     private NavigableMap!(E, V) m;

    //     this(NavigableMap!(E, V) map) { m = map; }

    //     Iterator!E iterator() {
    //         TreeMap!(E, V) mm = cast(TreeMap!(E, V))m;
    //         if (mm !is null)
    //             return mm.keyIterator();
    //         else
    //             return (cast(TreeMap.NavigableSubMap!(E, V))m).keyIterator();
    //     }

    //     Iterator!E descendingIterator() {
    //         TreeMap!(E, V) mm = cast(TreeMap!(E, V))m;
    //         if (mm !is null)
    //             return mm.descendingKeyIterator();
    //         else
    //             return (cast(TreeMap.NavigableSubMap!(E, V))m).descendingKeyIterator();
    //     }

    //     override int size() { return m.size(); }
    //     override bool isEmpty() { return m.isEmpty(); }
    //     override bool contains(K o) { return m.containsKey(o); }
    //     override void clear() { m.clear(); }
    //     E lower(E e) { return m.lowerKey(e); }
    //     E floor(E e) { return m.floorKey(e); }
    //     E ceiling(E e) { return m.ceilingKey(e); }
    //     E higher(E e) { return m.higherKey(e); }
    //     E first() { return m.firstKey(); }
    //     E last() { return m.lastKey(); }
    //     // Comparator!E comparator() { return m.comparator(); }
    //     E pollFirst() {
    //         MapEntry!(E, V) e = m.pollFirstEntry();
    //         return (e is null) ? E.init : e.getKey();
    //     }
    //     E pollLast() {
    //         MapEntry!(E, V) e = m.pollLastEntry();
    //         return (e is null) ? E.init : e.getKey();
    //     }
    //     bool remove(E o) {
    //         int oldSize = size();
    //         m.remove(o);
    //         return size()  !is  oldSize;
    //     }
    //     NavigableSet!E subSet(E fromElement, bool fromInclusive,
    //                                   E toElement,   bool toInclusive) {
    //         return new KeySet!(E, V)(m.subMap(fromElement, fromInclusive,
    //                                       toElement,   toInclusive));
    //     }
    //     NavigableSet!E headSet(E toElement, bool inclusive) {
    //         return new KeySet!(E, V)(m.headMap(toElement, inclusive));
    //     }
    //     NavigableSet!E tailSet(E fromElement, bool inclusive) {
    //         return new KeySet!(E, V)(m.tailMap(fromElement, inclusive));
    //     }
    //     SortedSet!E subSet(E fromElement, E toElement) {
    //         return subSet(fromElement, true, toElement, false);
    //     }
    //     SortedSet!E headSet(E toElement) {
    //         return headSet(toElement, false);
    //     }
    //     SortedSet!E tailSet(E fromElement) {
    //         return tailSet(fromElement, true);
    //     }
    //     NavigableSet!E descendingSet() {
    //         return new KeySet!(E, V)(m.descendingMap());
    //     }

    //     // Spliterator!E spliterator() {
    //     //     return keySpliteratorFor(m);
    //     // }
    // }

    /**
     * Base class for TreeMap Iterators
     */

    mixin template TreeMapIterator() {
        TreeMapEntry!(K,V) next;
        TreeMapEntry!(K,V) lastReturned;
        int expectedModCount;

        this() {
            expectedModCount = modCount;
            lastReturned = null;
            next = getFirstEntry();
        }

        final bool empty() {
            return next is null;
        }

        final void popFront() {
            TreeMapEntry!(K,V) e = next;
            if (e is null)
                throw new NoSuchElementException();
            if (modCount  !is  expectedModCount)
                throw new ConcurrentModificationException();
            next = successor(e);
            lastReturned = e;
            // return e;
        }

        // final TreeMapEntry!(K,V) prevEntry() {
        //     TreeMapEntry!(K,V) e = next;
        //     if (e is null)
        //         throw new NoSuchElementException();
        //     if (modCount  !is  expectedModCount)
        //         throw new ConcurrentModificationException();
        //     next = predecessor(e);
        //     lastReturned = e;
        //     return e;
        // }
    }

    final class KeyInputRange :  InputRange!K {
        mixin TreeMapIterator;

        final K front() @property { return next.key; }

        // https://forum.dlang.org/thread/amzthhonuozlobghqqgk@forum.dlang.org?page=1
        // https://issues.dlang.org/show_bug.cgi?id=18036
        final K moveFront() @property { throw new NotSupportedException(); }
        
        int opApply(scope int delegate(K) dg) {
            if(dg is null)
                throw new NullPointerException();

            int result = 0;
            int expectedModCount = modCount;
            for (TreeMapEntry!(K, V) e = getFirstEntry(); e !is null; e = successor(e)) {
                result = dg(e.key);
                if(result != 0) return result;
            }

            if (expectedModCount !is modCount) 
                throw new ConcurrentModificationException();

            return result;
        }

        int opApply(scope int delegate(size_t, K) dg) {
            if(dg is null)
                throw new NullPointerException();

            int result = 0;
            int mc = modCount;
            size_t index = 0;
             for (TreeMapEntry!(K, V) e = getFirstEntry(); e !is null; e = successor(e)) {
                result = dg(index++, e.key);
                if(result != 0) return result;
            }

            if(modCount != mc)
                throw new ConcurrentModificationException();

            return result;
        }
    }
    
    final class ValueInputRange :  InputRange!V {
        mixin TreeMapIterator;

        final V front() @property { return next.value; }

        final V moveFront() @property { throw new NotSupportedException(); }
        
        int opApply(scope int delegate(V) dg) {
            if(dg is null)
                throw new NullPointerException();

            int result = 0;
            int mc = modCount;
             for (TreeMapEntry!(K, V) e = getFirstEntry(); e !is null; e = successor(e)) {
                result = dg(e.value);
                if(result != 0) return result;
            }

            if(modCount != mc)
                throw new ConcurrentModificationException();

            return result;
        }

        int opApply(scope int delegate(size_t, V) dg) {
            if(dg is null)
                throw new NullPointerException();

            int result = 0;
            int mc = modCount;
            size_t index = 0;
            for (TreeMapEntry!(K, V) e = getFirstEntry(); e !is null; e = successor(e)) {
                result = dg(index++, e.value);
                if(result != 0) return result;
            }

            if(modCount != mc)
                throw new ConcurrentModificationException();

            return result;
        }
    }

    // abstract class PrivateEntryIterator(T) : Iterator!T {
    //     TreeMapEntry!(K,V) next;
    //     TreeMapEntry!(K,V) lastReturned;
    //     int expectedModCount;

    //     this(TreeMapEntry!(K,V) first) {
    //         expectedModCount = modCount;
    //         lastReturned = null;
    //         next = first;
    //     }

    //     final bool hasNext() {
    //         return next !is null;
    //     }

    //     final TreeMapEntry!(K,V) nextEntry() {
    //         TreeMapEntry!(K,V) e = next;
    //         if (e is null)
    //             throw new NoSuchElementException();
    //         if (modCount  !is  expectedModCount)
    //             throw new ConcurrentModificationException();
    //         next = successor(e);
    //         lastReturned = e;
    //         return e;
    //     }

    //     final TreeMapEntry!(K,V) prevEntry() {
    //         TreeMapEntry!(K,V) e = next;
    //         if (e is null)
    //             throw new NoSuchElementException();
    //         if (modCount  !is  expectedModCount)
    //             throw new ConcurrentModificationException();
    //         next = predecessor(e);
    //         lastReturned = e;
    //         return e;
    //     }

    //     void remove() {
    //         if (lastReturned is null)
    //             throw new IllegalStateException();
    //         if (modCount  !is  expectedModCount)
    //             throw new ConcurrentModificationException();
    //         // deleted entries are replaced by their successors
    //         if (lastReturned.left !is null && lastReturned.right !is null)
    //             next = lastReturned;
    //         deleteEntry(lastReturned);
    //         expectedModCount = modCount;
    //         lastReturned = null;
    //     }
    // }

    // final class EntryIterator : PrivateEntryIterator!(MapEntry!(K,V)) {
    //     this(TreeMapEntry!(K,V) first) {
    //         super(first);
    //     }
    //     MapEntry!(K,V) next() {
    //         return nextEntry();
    //     }
    // }

    // final class ValueIterator : PrivateEntryIterator!V {
    //     this(TreeMapEntry!(K,V) first) {
    //         super(first);
    //     }
    //     V next() {
    //         return nextEntry().value;
    //     }
    // }

    // final class KeyIterator : PrivateEntryIterator!K {
    //     this(TreeMapEntry!(K,V) first) {
    //         super(first);
    //     }
    //     K next() {
    //         return nextEntry().key;
    //     }
    // }

    // final class DescendingKeyIterator : PrivateEntryIterator!K {
    //     this(TreeMapEntry!(K,V) first) {
    //         super(first);
    //     }
    //     K next() {
    //         return prevEntry().key;
    //     }

    //     override void remove() {
    //         if (lastReturned is null)
    //             throw new IllegalStateException();
    //         if (modCount  !is  expectedModCount)
    //             throw new ConcurrentModificationException();
    //         deleteEntry(lastReturned);
    //         lastReturned = null;
    //         expectedModCount = modCount;
    //     }
    // }

    /**
     * Compares two keys using the correct comparison method for this TreeMap.
     */
    // final private int compare(K k1, K k2) {
    //     if(k1 == k2) return 0;
    //     else if(k1 > k2) return 1;
    //     else return -1;
    // }


    // SubMaps

    /**
     * Dummy value serving as unmatchable fence key for unbounded
     * SubMapIterators
     */
    private __gshared Object UNBOUNDED;

    shared static this()
    {
        UNBOUNDED = new Object();
    }

    /**
     * This class exists solely for the sake of serialization
     * compatibility with previous releases of TreeMap that did not
     * support NavigableMap.  It translates an old-version SubMap into
     * a new-version AscendingSubMap. This class is never otherwise
     * used.
     *
     * @serial include
     */
    private class SubMap : AbstractMap!(K,V), SortedMap!(K,V) {

        private bool fromStart = false, toEnd = false;
        private K fromKey, toKey;
        // private Object readResolve() {
        //     return new AscendingSubMap<>(TreeMap.this,
        //                                  fromStart, fromKey, true,
        //                                  toEnd, toKey, false);
        // }
        Set!(MapEntry!(K,V)) entrySet() { throw new InternalError(); }
        K lastKey() { throw new InternalError(); }
        K firstKey() { throw new InternalError(); }
        SortedMap!(K,V) subMap(K fromKey, K toKey) { throw new InternalError(); }
        SortedMap!(K,V) headMap(K toKey) { throw new InternalError(); }
        SortedMap!(K,V) tailMap(K fromKey) { throw new InternalError(); }
        Comparator!K comparator() { throw new InternalError(); }

        
        override bool opEquals(IObject o) {
            return opEquals(cast(Object) o);
        }
        
        override bool opEquals(Object o) {
            return super.opEquals(o);
        }

        override size_t toHash() @trusted nothrow {
            return super.toHash();
        }

        override string toString() {
            return super.toString();
        }

        override K[] keySet() {
            return super.keySet();
        }

        override V[] values() {
            return super.values;
        }
    }


    /**
     * Returns the first Entry in the TreeMap (according to the TreeMap's
     * key-sort function).  Returns null if the TreeMap is empty.
     */
    final TreeMapEntry!(K,V) getFirstEntry() {
        TreeMapEntry!(K,V) p = root;
        if (p !is null)
            while (p.left !is null)
                p = p.left;
        return p;
    }

    /**
     * Returns the last Entry in the TreeMap (according to the TreeMap's
     * key-sort function).  Returns null if the TreeMap is empty.
     */
    final TreeMapEntry!(K,V) getLastEntry() {
        TreeMapEntry!(K,V) p = root;
        if (p !is null)
            while (p.right !is null)
                p = p.right;
        return p;
    }

    

    /**
     * Balancing operations.
     *
     * Implementations of rebalancings during insertion and deletion are
     * slightly different than the CLR version.  Rather than using dummy
     * nilnodes, we use a set of accessors that deal properly with null.  They
     * are used to avoid messiness surrounding nullness checks in the main
     * algorithms.
     */

    private static bool colorOf(K,V)(TreeMapEntry!(K,V) p) {
        return (p is null ? BLACK : p.color);
    }

    private static TreeMapEntry!(K,V) parentOf(K,V)(TreeMapEntry!(K,V) p) {
        return (p is null ? null: p.parent);
    }

    private static void setColor(K,V)(TreeMapEntry!(K,V) p, bool c) {
        if (p !is null)
            p.color = c;
    }

    private static TreeMapEntry!(K,V) leftOf(K,V)(TreeMapEntry!(K,V) p) {
        return (p is null) ? null: p.left;
    }

    private static TreeMapEntry!(K,V) rightOf(K,V)(TreeMapEntry!(K,V) p) {
        return (p is null) ? null: p.right;
    }

    /** From CLR */
    private void rotateLeft(TreeMapEntry!(K,V) p) {
        if (p !is null) {
            TreeMapEntry!(K,V) r = p.right;
            p.right = r.left;
            if (r.left !is null)
                r.left.parent = p;
            r.parent = p.parent;
            if (p.parent is null)
                root = r;
            else if (p.parent.left == p)
                p.parent.left = r;
            else
                p.parent.right = r;
            r.left = p;
            p.parent = r;
        }
    }

    /** From CLR */
    private void rotateRight(TreeMapEntry!(K,V) p) {
        if (p !is null) {
            TreeMapEntry!(K,V) l = p.left;
            p.left = l.right;
            if (l.right !is null) l.right.parent = p;
            l.parent = p.parent;
            if (p.parent is null)
                root = l;
            else if (p.parent.right == p)
                p.parent.right = l;
            else p.parent.left = l;
            l.right = p;
            p.parent = l;
        }
    }

    /** From CLR */
    private void fixAfterInsertion(TreeMapEntry!(K,V) x) {
        x.color = RED;

        while (x !is null && x  !is  root && x.parent.color == RED) {
            if (parentOf(x) == leftOf(parentOf(parentOf(x)))) {
                TreeMapEntry!(K,V) y = rightOf(parentOf(parentOf(x)));
                if (colorOf(y) == RED) {
                    setColor(parentOf(x), BLACK);
                    setColor(y, BLACK);
                    setColor(parentOf(parentOf(x)), RED);
                    x = parentOf(parentOf(x));
                } else {
                    if (x == rightOf(parentOf(x))) {
                        x = parentOf(x);
                        rotateLeft(x);
                    }
                    setColor(parentOf(x), BLACK);
                    setColor(parentOf(parentOf(x)), RED);
                    rotateRight(parentOf(parentOf(x)));
                }
            } else {
                TreeMapEntry!(K,V) y = leftOf(parentOf(parentOf(x)));
                if (colorOf(y) == RED) {
                    setColor(parentOf(x), BLACK);
                    setColor(y, BLACK);
                    setColor(parentOf(parentOf(x)), RED);
                    x = parentOf(parentOf(x));
                } else {
                    if (x == leftOf(parentOf(x))) {
                        x = parentOf(x);
                        rotateRight(x);
                    }
                    setColor(parentOf(x), BLACK);
                    setColor(parentOf(parentOf(x)), RED);
                    rotateLeft(parentOf(parentOf(x)));
                }
            }
        }
        root.color = BLACK;
    }

    /**
     * Delete node p, and then rebalance the tree.
     */
    private void deleteEntry(TreeMapEntry!(K,V) p) {
        modCount++;
        _size--;

        // If strictly internal, copy successor's element to p and then make p
        // point to successor.
        if (p.left !is null && p.right !is null) {
            TreeMapEntry!(K,V) s = successor(p);
            p.key = s.key;
            p.value = s.value;
            p = s;
        } // p has 2 children

        // Start fixup at replacement node, if it exists.
        TreeMapEntry!(K,V) replacement = (p.left !is null ? p.left : p.right);

        if (replacement !is null) {
            // Link replacement to parent
            replacement.parent = p.parent;
            if (p.parent is null)
                root = replacement;
            else if (p == p.parent.left)
                p.parent.left  = replacement;
            else
                p.parent.right = replacement;

            // Null out links so they are OK to use by fixAfterDeletion.
            p.left = p.right = p.parent = null;

            // Fix replacement
            if (p.color == BLACK)
                fixAfterDeletion(replacement);
        } else if (p.parent is null) { // return if we are the only node.
            root = null;
        } else { //  No children. Use self as phantom replacement and unlink.
            if (p.color == BLACK)
                fixAfterDeletion(p);

            if (p.parent !is null) {
                if (p == p.parent.left)
                    p.parent.left = null;
                else if (p == p.parent.right)
                    p.parent.right = null;
                p.parent = null;
            }
        }
    }

    /** From CLR */
    private void fixAfterDeletion(TreeMapEntry!(K,V) x) {
        while (x  !is  root && colorOf(x) == BLACK) {
            if (x == leftOf(parentOf(x))) {
                TreeMapEntry!(K,V) sib = rightOf(parentOf(x));

                if (colorOf(sib) == RED) {
                    setColor(sib, BLACK);
                    setColor(parentOf(x), RED);
                    rotateLeft(parentOf(x));
                    sib = rightOf(parentOf(x));
                }

                if (colorOf(leftOf(sib))  == BLACK &&
                    colorOf(rightOf(sib)) == BLACK) {
                    setColor(sib, RED);
                    x = parentOf(x);
                } else {
                    if (colorOf(rightOf(sib)) == BLACK) {
                        setColor(leftOf(sib), BLACK);
                        setColor(sib, RED);
                        rotateRight(sib);
                        sib = rightOf(parentOf(x));
                    }
                    setColor(sib, colorOf(parentOf(x)));
                    setColor(parentOf(x), BLACK);
                    setColor(rightOf(sib), BLACK);
                    rotateLeft(parentOf(x));
                    x = root;
                }
            } else { // symmetric
                TreeMapEntry!(K,V) sib = leftOf(parentOf(x));

                if (colorOf(sib) == RED) {
                    setColor(sib, BLACK);
                    setColor(parentOf(x), RED);
                    rotateRight(parentOf(x));
                    sib = leftOf(parentOf(x));
                }

                if (colorOf(rightOf(sib)) == BLACK &&
                    colorOf(leftOf(sib)) == BLACK) {
                    setColor(sib, RED);
                    x = parentOf(x);
                } else {
                    if (colorOf(leftOf(sib)) == BLACK) {
                        setColor(rightOf(sib), BLACK);
                        setColor(sib, RED);
                        rotateLeft(sib);
                        sib = leftOf(parentOf(x));
                    }
                    setColor(sib, colorOf(parentOf(x)));
                    setColor(parentOf(x), BLACK);
                    setColor(leftOf(sib), BLACK);
                    rotateRight(parentOf(x));
                    x = root;
                }
            }
        }

        setColor(x, BLACK);
    }

    // private static final long serialVersionUID = 919286545866124006L;

    /**
     * Save the state of the {@code TreeMap} instance to a stream (i.e.,
     * serialize it).
     *
     * @serialData The <em>size</em> of the TreeMap (the number of key-value
     *             mappings) is emitted (int), followed by the key (Object)
     *             and value (Object) for each key-value mapping represented
     *             by the TreeMap. The key-value mappings are emitted in
     *             key-order (as determined by the TreeMap's Comparator,
     *             or by the keys' natural ordering if the TreeMap has no
     *             Comparator).
     */
    // private void writeObject(java.io.ObjectOutputStream s)
    //     throws java.io.IOException {
    //     // Write out the Comparator and any hidden stuff
    //     s.defaultWriteObject();

    //     // Write out size (number of Mappings)
    //     s.writeInt(size);

    //     // Write out keys and values (alternating)
    //     for (Iterator!(MapEntry!(K,V)) i = entrySet().iterator(); i.hasNext(); ) {
    //         MapEntry!(K,V) e = i.next();
    //         s.writeObject(e.getKey());
    //         s.writeObject(e.getValue());
    //     }
    // }

    /**
     * Reconstitute the {@code TreeMap} instance from a stream (i.e.,
     * deserialize it).
     */
    // private void readObject(final java.io.ObjectInputStream s)
    //     throws java.io.IOException, ClassNotFoundException {
    //     // Read in the Comparator and any hidden stuff
    //     s.defaultReadObject();

    //     // Read in size
    //     int size = s.readInt();

    //     buildFromSorted(size, null, s, null);
    // }

    /** Intended to be called only from TreeSet.readObject */
    // void readTreeSet(int size, java.io.ObjectInputStream s, V defaultVal) {
    //     buildFromSorted(size, null, s, defaultVal);
    // }

    /** Intended to be called only from TreeSet.addAll */
    // void addAllForTreeSet(SortedSet!K set, V defaultVal) {
    //     try {
    //         buildFromSorted(set.size(), set.iterator(), null, defaultVal);
    //     } catch (IOException cannotHappen) {
    //     } catch (ClassNotFoundException cannotHappen) {
    //     }
    // }


    /**
     * Linear time tree building algorithm from sorted data.  Can accept keys
     * and/or values from iterator or stream. This leads to too many
     * parameters, but seems better than alternatives.  The four formats
     * that this method accepts are:
     *
     *    1) An iterator of Map.Entries.  (it !is null, defaultVal is null).
     *    2) An iterator of keys.         (it !is null, defaultVal !is null).
     *    3) A stream of alternating serialized keys and values.
     *                                   (it is null, defaultVal is null).
     *    4) A stream of serialized keys. (it is null, defaultVal !is null).
     *
     * It is assumed that the comparator of the TreeMap is already set prior
     * to calling this method.
     *
     * @param size the number of keys (or key-value pairs) to be read from
     *        the iterator or stream
     * @param it If non-null, new entries are created from entries
     *        or keys read from this iterator.
     * @param str If non-null, new entries are created from keys and
     *        possibly values read from this stream in serialized form.
     *        Exactly one of it and str should be non-null.
     * @param defaultVal if non-null, this default value is used for
     *        each value in the map.  If null, each value is read from
     *        iterator or stream, as described above.
     * @throws java.io.IOException propagated from stream reads. This cannot
     *         occur if str is null.
     * @throws ClassNotFoundException propagated from readObject.
     *         This cannot occur if str is null.
     */
    // private void buildFromSorted(int size, Iterator<?> it,
    //                             //  java.io.ObjectInputStream str,
    //                              V defaultVal) {
    //     this._size = size;
    //     root = buildFromSorted(0, 0, size-1, computeRedLevel(size),
    //                            it, defaultVal);
    // }

    /**
     * Recursive "helper method" that does the real work of the
     * previous method.  Identically named parameters have
     * identical definitions.  Additional parameters are documented below.
     * It is assumed that the comparator and size fields of the TreeMap are
     * already set prior to calling this method.  (It ignores both fields.)
     *
     * @param level the current level of tree. Initial call should be 0.
     * @param lo the first element index of this subtree. Initial should be 0.
     * @param hi the last element index of this subtree.  Initial should be
     *        size-1.
     * @param redLevel the level at which nodes should be red.
     *        Must be equal to computeRedLevel for tree of this size.
     */
    // private final TreeMapEntry!(K,V) buildFromSorted(int level, int lo, int hi,
    //                                          int redLevel,
    //                                          Iterator<?> it,
    //                                         //  java.io.ObjectInputStream str,
    //                                          V defaultVal) {
    //     /*
    //      * Strategy: The root is the middlemost element. To get to it, we
    //      * have to first recursively construct the entire left subtree,
    //      * so as to grab all of its elements. We can then proceed with right
    //      * subtree.
    //      *
    //      * The lo and hi arguments are the minimum and maximum
    //      * indices to pull out of the iterator or stream for current subtree.
    //      * They are not actually indexed, we just proceed sequentially,
    //      * ensuring that items are extracted in corresponding order.
    //      */

    //     if (hi < lo) return null;

    //     int mid = (lo + hi) >>> 1;

    //     TreeMapEntry!(K,V) left  = null;
    //     if (lo < mid)
    //         left = buildFromSorted(level+1, lo, mid - 1, redLevel,
    //                                it, str, defaultVal);

    //     // extract key and/or value from iterator or stream
    //     K key;
    //     V value;
    //     if (it !is null) {
    //         if (defaultVal is null) {
    //             MapEntry<?,?> entry = (MapEntry<?,?>)it.next();
    //             key = (K)entry.getKey();
    //             value = (V)entry.getValue();
    //         } else {
    //             key = (K)it.next();
    //             value = defaultVal;
    //         }
    //     } else { // use stream
    //         key = (K) str.readObject();
    //         value = (defaultVal !is null ? defaultVal : (V) str.readObject());
    //     }

    //     TreeMapEntry!(K,V) middle =  new Entry<>(key, value, null);

    //     // color nodes in non-full bottommost level red
    //     if (level == redLevel)
    //         middle.color = RED;

    //     if (left !is null) {
    //         middle.left = left;
    //         left.parent = middle;
    //     }

    //     if (mid < hi) {
    //         TreeMapEntry!(K,V) right = buildFromSorted(level+1, mid+1, hi, redLevel,
    //                                            it, str, defaultVal);
    //         middle.right = right;
    //         right.parent = middle;
    //     }

    //     return middle;
    // }

    /**
     * Find the level down to which to assign all nodes BLACK.  This is the
     * last `full' level of the complete binary tree produced by
     * buildTree. The remaining nodes are colored RED. (This makes a `nice'
     * set of color assignments wrt future insertions.) This level number is
     * computed by finding the number of splits needed to reach the zeroeth
     * node.  (The answer is ~lg(N), but in any case must be computed by same
     * quick O(lg(N)) loop.)
     */
    private static int computeRedLevel(int sz) {
        int level = 0;
        for (int m = sz - 1; m >= 0; m = m / 2 - 1)
            level++;
        return level;
    }

    /**
     * Currently, we support Spliterator-based versions only for the
     * full map, in either plain of descending form, otherwise relying
     * on defaults because size estimation for submaps would dominate
     * costs. The type tests needed to check these for key views are
     * not very nice but avoid disrupting existing class
     * structures. Callers must use plain default spliterators if this
     * returns null.
     */
    // static !K Spliterator!K keySpliteratorFor(NavigableMap<K,?> m) {
    //     if (m instanceof TreeMap) {
    //     TreeMap<K,Object> t =
    //             (TreeMap<K,Object>) m;
    //         return t.keySpliterator();
    //     }
    //     if (m instanceof DescendingSubMap) {
    //     DescendingSubMap<K,?> dm =
    //             (DescendingSubMap<K,?>) m;
    //         TreeMap<K,?> tm = dm.m;
    //         if (dm == tm.descendingMap) {
    //         TreeMap<K,Object> t =
    //                 (TreeMap<K,Object>) tm;
    //             return t.descendingKeySpliterator();
    //         }
    //     }
    // NavigableSubMap<K,?> sm =
    //         (NavigableSubMap<K,?>) m;
    //     return sm.keySpliterator();
    // }

    // final Spliterator!K keySpliterator() {
    //     return new KeySpliterator!(K,V)(this, null, null, 0, -1, 0);
    // }

    // final Spliterator!K descendingKeySpliterator() {
    //     return new DescendingKeySpliterator!(K,V)(this, null, null, 0, -2, 0);
    // }

    /**
     * Base class for spliterators.  Iteration starts at a given
     * origin and continues up to but not including a given fence (or
     * null for end).  At top-level, for ascending cases, the first
     * split uses the root as left-fence/right-origin. From there,
     * right-hand splits replace the current fence with its left
     * child, also serving as origin for the split-off spliterator.
     * Left-hands are symmetric. Descending versions place the origin
     * at the end and invert ascending split rules.  This base class
     * is non-commital about directionality, or whether the top-level
     * spliterator covers the whole tree. This means that the actual
     * split mechanics are located in subclasses. Some of the subclass
     * trySplit methods are identical (except for return types), but
     * not nicely factorable.
     *
     * Currently, subclass versions exist only for the full map
     * (including descending keys via its descendingMap).  Others are
     * possible but currently not worthwhile because submaps require
     * O(n) computations to determine size, which substantially limits
     * potential speed-ups of using custom Spliterators versus default
     * mechanics.
     *
     * To boostrap initialization, external constructors use
     * negative size estimates: -1 for ascend, -2 for descend.
     */
    // static class TreeMapSpliterator!(K,V) {
    //     final TreeMap!(K,V) tree;
    //     TreeMapEntry!(K,V) current; // traverser; initially first node in range
    //     TreeMapEntry!(K,V) fence;   // one past last, or null
    //     int side;                   // 0: top, -1: is a left split, +1: right
    //     int est;                    // size estimate (exact only for top-level)
    //     int expectedModCount;       // for CME checks

    //     TreeMapSpliterator(TreeMap!(K,V) tree,
    //                        TreeMapEntry!(K,V) origin, TreeMapEntry!(K,V) fence,
    //                        int side, int est, int expectedModCount) {
    //         this.tree = tree;
    //         this.current = origin;
    //         this.fence = fence;
    //         this.side = side;
    //         this.est = est;
    //         this.expectedModCount = expectedModCount;
    //     }

    //     final int getEstimate() { // force initialization
    //         int s; TreeMap!(K,V) t;
    //         if ((s = est) < 0) {
    //             if ((t = tree) !is null) {
    //                 current = (s == -1) ? t.getFirstEntry() : t.getLastEntry();
    //                 s = est = t.size;
    //                 expectedModCount = t.modCount;
    //             }
    //             else
    //                 s = est = 0;
    //         }
    //         return s;
    //     }

    //     final long estimateSize() {
    //         return (long)getEstimate();
    //     }
    // }

    // static final class KeySpliterator!(K,V)
    //     : TreeMapSpliterator!(K,V)
    //     , Spliterator!K {
    //     KeySpliterator(TreeMap!(K,V) tree,
    //                    TreeMapEntry!(K,V) origin, TreeMapEntry!(K,V) fence,
    //                    int side, int est, int expectedModCount) {
    //         super(tree, origin, fence, side, est, expectedModCount);
    //     }

    //     KeySpliterator!(K,V) trySplit() {
    //         if (est < 0)
    //             getEstimate(); // force initialization
    //         int d = side;
    //         TreeMapEntry!(K,V) e = current, f = fence,
    //             s = ((e is null || e == f) ? null :      // empty
    //                  (d == 0)              ? tree.root : // was top
    //                  (d >  0)              ? e.right :   // was right
    //                  (d <  0 && f !is null) ? f.left :    // was left
    //                  null);
    //         if (s !is null && s  !is  e && s  !is  f &&
    //             tree.compare(e.key, s.key) < 0) {        // e not already past s
    //             side = 1;
    //             return new KeySpliterator<>
    //                 (tree, e, current = s, -1, est >>>= 1, expectedModCount);
    //         }
    //         return null;
    //     }

    //     void forEachRemaining(Consumer!K action) {
    //         if (action is null)
    //             throw new NullPointerException();
    //         if (est < 0)
    //             getEstimate(); // force initialization
    //         TreeMapEntry!(K,V) f = fence, e, p, pl;
    //         if ((e = current) !is null && e  !is  f) {
    //             current = f; // exhaust
    //             do {
    //                 action.accept(e.key);
    //                 if ((p = e.right) !is null) {
    //                     while ((pl = p.left) !is null)
    //                         p = pl;
    //                 }
    //                 else {
    //                     while ((p = e.parent) !is null && e == p.right)
    //                         e = p;
    //                 }
    //             } while ((e = p) !is null && e  !is  f);
    //             if (tree.modCount  !is  expectedModCount)
    //                 throw new ConcurrentModificationException();
    //         }
    //     }

    //     bool tryAdvance(Consumer!K action) {
    //         TreeMapEntry!(K,V) e;
    //         if (action is null)
    //             throw new NullPointerException();
    //         if (est < 0)
    //             getEstimate(); // force initialization
    //         if ((e = current) is null || e == fence)
    //             return false;
    //         current = successor(e);
    //         action.accept(e.key);
    //         if (tree.modCount  !is  expectedModCount)
    //             throw new ConcurrentModificationException();
    //         return true;
    //     }

    //     int characteristics() {
    //         return (side == 0 ? Spliterator.SIZED : 0) |
    //             Spliterator.DISTINCT | Spliterator.SORTED | Spliterator.ORDERED;
    //     }

    //     final Comparator!K  getComparator() {
    //         return tree.comparator;
    //     }

    // }

    // static final class DescendingKeySpliterator!(K,V)
    //     : TreeMapSpliterator!(K,V)
    //     , Spliterator!K {
    //     DescendingKeySpliterator(TreeMap!(K,V) tree,
    //                              TreeMapEntry!(K,V) origin, TreeMapEntry!(K,V) fence,
    //                              int side, int est, int expectedModCount) {
    //         super(tree, origin, fence, side, est, expectedModCount);
    //     }

    //     DescendingKeySpliterator!(K,V) trySplit() {
    //         if (est < 0)
    //             getEstimate(); // force initialization
    //         int d = side;
    //         TreeMapEntry!(K,V) e = current, f = fence,
    //                 s = ((e is null || e == f) ? null :      // empty
    //                      (d == 0)              ? tree.root : // was top
    //                      (d <  0)              ? e.left :    // was left
    //                      (d >  0 && f !is null) ? f.right :   // was right
    //                      null);
    //         if (s !is null && s  !is  e && s  !is  f &&
    //             tree.compare(e.key, s.key) > 0) {       // e not already past s
    //             side = 1;
    //             return new DescendingKeySpliterator<>
    //                     (tree, e, current = s, -1, est >>>= 1, expectedModCount);
    //         }
    //         return null;
    //     }

    //     void forEachRemaining(Consumer!K action) {
    //         if (action is null)
    //             throw new NullPointerException();
    //         if (est < 0)
    //             getEstimate(); // force initialization
    //         TreeMapEntry!(K,V) f = fence, e, p, pr;
    //         if ((e = current) !is null && e  !is  f) {
    //             current = f; // exhaust
    //             do {
    //                 action.accept(e.key);
    //                 if ((p = e.left) !is null) {
    //                     while ((pr = p.right) !is null)
    //                         p = pr;
    //                 }
    //                 else {
    //                     while ((p = e.parent) !is null && e == p.left)
    //                         e = p;
    //                 }
    //             } while ((e = p) !is null && e  !is  f);
    //             if (tree.modCount  !is  expectedModCount)
    //                 throw new ConcurrentModificationException();
    //         }
    //     }

    //     bool tryAdvance(Consumer!K action) {
    //         TreeMapEntry!(K,V) e;
    //         if (action is null)
    //             throw new NullPointerException();
    //         if (est < 0)
    //             getEstimate(); // force initialization
    //         if ((e = current) is null || e == fence)
    //             return false;
    //         current = predecessor(e);
    //         action.accept(e.key);
    //         if (tree.modCount  !is  expectedModCount)
    //             throw new ConcurrentModificationException();
    //         return true;
    //     }

    //     int characteristics() {
    //         return (side == 0 ? Spliterator.SIZED : 0) |
    //             Spliterator.DISTINCT | Spliterator.ORDERED;
    //     }
    // }

    // static final class ValueSpliterator!(K,V)
    //         : TreeMapSpliterator!(K,V)
    //         , Spliterator!V {
    //     ValueSpliterator(TreeMap!(K,V) tree,
    //                      TreeMapEntry!(K,V) origin, TreeMapEntry!(K,V) fence,
    //                      int side, int est, int expectedModCount) {
    //         super(tree, origin, fence, side, est, expectedModCount);
    //     }

    //     ValueSpliterator!(K,V) trySplit() {
    //         if (est < 0)
    //             getEstimate(); // force initialization
    //         int d = side;
    //         TreeMapEntry!(K,V) e = current, f = fence,
    //                 s = ((e is null || e == f) ? null :      // empty
    //                      (d == 0)              ? tree.root : // was top
    //                      (d >  0)              ? e.right :   // was right
    //                      (d <  0 && f !is null) ? f.left :    // was left
    //                      null);
    //         if (s !is null && s  !is  e && s  !is  f &&
    //             tree.compare(e.key, s.key) < 0) {        // e not already past s
    //             side = 1;
    //             return new ValueSpliterator<>
    //                     (tree, e, current = s, -1, est >>>= 1, expectedModCount);
    //         }
    //         return null;
    //     }

    //     void forEachRemaining(Consumer<V> action) {
    //         if (action is null)
    //             throw new NullPointerException();
    //         if (est < 0)
    //             getEstimate(); // force initialization
    //         TreeMapEntry!(K,V) f = fence, e, p, pl;
    //         if ((e = current) !is null && e  !is  f) {
    //             current = f; // exhaust
    //             do {
    //                 action.accept(e.value);
    //                 if ((p = e.right) !is null) {
    //                     while ((pl = p.left) !is null)
    //                         p = pl;
    //                 }
    //                 else {
    //                     while ((p = e.parent) !is null && e == p.right)
    //                         e = p;
    //                 }
    //             } while ((e = p) !is null && e  !is  f);
    //             if (tree.modCount  !is  expectedModCount)
    //                 throw new ConcurrentModificationException();
    //         }
    //     }

    //     bool tryAdvance(Consumer<V> action) {
    //         TreeMapEntry!(K,V) e;
    //         if (action is null)
    //             throw new NullPointerException();
    //         if (est < 0)
    //             getEstimate(); // force initialization
    //         if ((e = current) is null || e == fence)
    //             return false;
    //         current = successor(e);
    //         action.accept(e.value);
    //         if (tree.modCount  !is  expectedModCount)
    //             throw new ConcurrentModificationException();
    //         return true;
    //     }

    //     int characteristics() {
    //         return (side == 0 ? Spliterator.SIZED : 0) | Spliterator.ORDERED;
    //     }
    // }

    // static final class EntrySpliterator!(K,V)
    //     : TreeMapSpliterator!(K,V)
    //     , Spliterator!(MapEntry!(K,V)) {
    //     EntrySpliterator(TreeMap!(K,V) tree,
    //                      TreeMapEntry!(K,V) origin, TreeMapEntry!(K,V) fence,
    //                      int side, int est, int expectedModCount) {
    //         super(tree, origin, fence, side, est, expectedModCount);
    //     }

    //     EntrySpliterator!(K,V) trySplit() {
    //         if (est < 0)
    //             getEstimate(); // force initialization
    //         int d = side;
    //         TreeMapEntry!(K,V) e = current, f = fence,
    //                 s = ((e is null || e == f) ? null :      // empty
    //                      (d == 0)              ? tree.root : // was top
    //                      (d >  0)              ? e.right :   // was right
    //                      (d <  0 && f !is null) ? f.left :    // was left
    //                      null);
    //         if (s !is null && s  !is  e && s  !is  f &&
    //             tree.compare(e.key, s.key) < 0) {        // e not already past s
    //             side = 1;
    //             return new EntrySpliterator<>
    //                     (tree, e, current = s, -1, est >>>= 1, expectedModCount);
    //         }
    //         return null;
    //     }

    //     void forEachRemaining(Consumer<MapEntry!(K, V)> action) {
    //         if (action is null)
    //             throw new NullPointerException();
    //         if (est < 0)
    //             getEstimate(); // force initialization
    //         TreeMapEntry!(K,V) f = fence, e, p, pl;
    //         if ((e = current) !is null && e  !is  f) {
    //             current = f; // exhaust
    //             do {
    //                 action.accept(e);
    //                 if ((p = e.right) !is null) {
    //                     while ((pl = p.left) !is null)
    //                         p = pl;
    //                 }
    //                 else {
    //                     while ((p = e.parent) !is null && e == p.right)
    //                         e = p;
    //                 }
    //             } while ((e = p) !is null && e  !is  f);
    //             if (tree.modCount  !is  expectedModCount)
    //                 throw new ConcurrentModificationException();
    //         }
    //     }

    //     bool tryAdvance(Consumer<MapEntry!(K,V)> action) {
    //         TreeMapEntry!(K,V) e;
    //         if (action is null)
    //             throw new NullPointerException();
    //         if (est < 0)
    //             getEstimate(); // force initialization
    //         if ((e = current) is null || e == fence)
    //             return false;
    //         current = successor(e);
    //         action.accept(e);
    //         if (tree.modCount  !is  expectedModCount)
    //             throw new ConcurrentModificationException();
    //         return true;
    //     }

    //     int characteristics() {
    //         return (side == 0 ? Spliterator.SIZED : 0) |
    //                 Spliterator.DISTINCT | Spliterator.SORTED | Spliterator.ORDERED;
    //     }

    //     override
    //     Comparator<MapEntry!(K, V)> getComparator() {
    //         // Adapt or create a key-based comparator
    //         if (tree.comparator !is null) {
    //             return MapEntry.comparingByKey(tree.comparator);
    //         }
    //         else {
    //             return (Comparator<MapEntry!(K, V)> & Serializable) (e1, e2) -> {
    //             
    //                 Comparable!K k1 = (Comparable!K) e1.getKey();
    //                 return k1.compareTo(e2.getKey());
    //             };
    //         }
    //     }
    // }

        override bool opEquals(IObject o) {
            return opEquals(cast(Object) o);
        }
        
        override bool opEquals(Object o) {
            return super.opEquals(o);
        }

        override size_t toHash() @trusted nothrow {
            return super.toHash();
        }

        override string toString() {
            return super.toString();
        }    
}


/**
* Node in the Tree.  Doubles as a means to pass key-value pairs back to
* user (see MapEntry).
*/

static final class TreeMapEntry(K,V) : MapEntry!(K,V) {
    K key;
    V value;
    TreeMapEntry!(K,V) left;
    TreeMapEntry!(K,V) right;
    TreeMapEntry!(K,V) parent;
    bool color = BLACK;

    /**
        * Make a new cell with given key, value, and parent, and with
        * {@code null} child links, and BLACK color.
        */
    this(K key, V value, TreeMapEntry!(K,V) parent) {
        this.key = key;
        this.value = value;
        this.parent = parent;
    }

    /**
        * Returns the key.
        *
        * @return the key
        */
    K getKey() {
        return key;
    }

    /**
        * Returns the value associated with the key.
        *
        * @return the value associated with the key
        */
    V getValue() {
        return value;
    }

    /**
        * Replaces the value currently associated with the key with the given
        * value.
        *
        * @return the value associated with the key before this method was
        *         called
        */
    V setValue(V value) {
        V oldValue = this.value;
        this.value = value;
        return oldValue;
    }

    bool opEquals(IObject o) {
        return opEquals(cast(Object) o);
    }

    override bool opEquals(Object o) {
        MapEntry!(K, V) e = cast(MapEntry!(K, V))o;
        if (e is null)
            return false;

        return key == e.getKey() && value == e.getValue();
    }

    override size_t toHash() @trusted nothrow {
        // int keyHash = (key is null ? 0 : key.hashCode());
        // int valueHash = (value is null ? 0 : value.hashCode());
        // return keyHash ^ valueHash;
        static if(is(K == class)) {
            size_t kHash = 0;
            if(key !is null) kHash = key.toHash();
        }
        else {
            size_t kHash = hashOf(key);
        }
        
        static if(is(V == class)) {
            size_t vHash = 0;
            if(value !is null) vHash = value.toHash();
        }
        else {
            size_t vHash = hashOf(value);
        }

        return kHash ^ vHash;
    }

    override string toString() {
        return key.to!string() ~ "=" ~ value.to!string();
    }
}


/**
 * @serial include
 */
abstract static class NavigableSubMap(K,V) : AbstractMap!(K,V) , NavigableMap!(K,V) {
    /**
     * The backing map.
     */
    protected TreeMap!(K,V) m;

    /**
     * Endpoints are represented as triples (fromStart, lo,
     * loInclusive) and (toEnd, hi, hiInclusive). If fromStart is
     * true, then the low (absolute) bound is the start of the
     * backing map, and the other values are ignored. Otherwise,
     * if loInclusive is true, lo is the inclusive bound, else lo
     * is the exclusive bound. Similarly for the upper bound.
     */
    K lo, hi;
    bool fromStart, toEnd;
    bool loInclusive, hiInclusive;

    int sizeModCount = 0;

    this(TreeMap!(K,V) m,
                    bool fromStart, K lo, bool loInclusive,
                    bool toEnd,     K hi, bool hiInclusive) {
        if (!fromStart && !toEnd) {
            if (compare(lo, hi) > 0)
                throw new IllegalArgumentException("fromKey > toKey");
        } else {
            // if (!fromStart) // type check
            //     compare(lo, lo);
            // if (!toEnd)
            //     compare(hi, hi);
        }

        this.m = m;
        this.fromStart = fromStart;
        this.lo = lo;
        this.loInclusive = loInclusive;
        this.toEnd = toEnd;
        this.hi = hi;
        this.hiInclusive = hiInclusive;

        this._size = -1;
        // if(fromStart && toEnd)
        //     this._size = m.size();
        // else
        //     updateSize();
    }

    // internal utilities

    final bool tooLow(K key) {
        if (!fromStart) {
            int c = compare(key, lo);
            if (c < 0 || (c == 0 && !loInclusive))
                return true;
        }
        return false;
    }

    final bool tooHigh(K key) {
        if (!toEnd) {
            int c = compare(key, hi);
            if (c > 0 || (c == 0 && !hiInclusive))
                return true;
        }
        return false;
    }

    final bool inRange(K key) {
        return !tooLow(key) && !tooHigh(key);
    }

    final bool inClosedRange(K key) {
        return (fromStart || compare(key, lo) >= 0)
            && (toEnd || compare(hi, key) >= 0);
    }

    final bool inRange(K key, bool inclusive) {
        return inclusive ? inRange(key) : inClosedRange(key);
    }

    /*
     * Absolute versions of relation operations.
     * Subclasses map to these using like-named "sub"
     * versions that invert senses for descending maps
     */

    final TreeMapEntry!(K,V) absLowest() {
        TreeMapEntry!(K,V) e =
            (fromStart ?  m.getFirstEntry() :
             (loInclusive ? m.getCeilingEntry(lo) :
                            m.getHigherEntry(lo)));
        return (e is null || tooHigh(e.key)) ? null : e;
    }

    final TreeMapEntry!(K,V) absHighest() {
        TreeMapEntry!(K,V) e =
            (toEnd ?  m.getLastEntry() :
             (hiInclusive ?  m.getFloorEntry(hi) :
                             m.getLowerEntry(hi)));
        return (e is null || tooLow(e.key)) ? null : e;
    }

    final TreeMapEntry!(K,V) absCeiling(K key) {
        if (tooLow(key))
            return absLowest();
        TreeMapEntry!(K,V) e = m.getCeilingEntry(key);
        return (e is null || tooHigh(e.key)) ? null : e;
    }

    final TreeMapEntry!(K,V) absHigher(K key) {
        if (tooLow(key))
            return absLowest();
        TreeMapEntry!(K,V) e = m.getHigherEntry(key);
        return (e is null || tooHigh(e.key)) ? null : e;
    }

    final TreeMapEntry!(K,V) absFloor(K key) {
        if (tooHigh(key))
            return absHighest();
        TreeMapEntry!(K,V) e = m.getFloorEntry(key);
        return (e is null || tooLow(e.key)) ? null : e;
    }

    final TreeMapEntry!(K,V) absLower(K key) {
        if (tooHigh(key))
            return absHighest();
        TreeMapEntry!(K,V) e = m.getLowerEntry(key);
        return (e is null || tooLow(e.key)) ? null : e;
    }

    /** Returns the absolute high fence for ascending traversal */
    final TreeMapEntry!(K,V) absHighFence() {
        return (toEnd ? null : (hiInclusive ?
                                m.getHigherEntry(hi) :
                                m.getCeilingEntry(hi)));
    }

    /** Return the absolute low fence for descending traversal  */
    final TreeMapEntry!(K,V) absLowFence() {
        return (fromStart ? null : (loInclusive ?
                                    m.getLowerEntry(lo) :
                                    m.getFloorEntry(lo)));
    }

    // Abstract methods defined in ascending vs descending classes
    // These relay to the appropriate absolute versions

    abstract TreeMapEntry!(K,V) subLowest();
    abstract TreeMapEntry!(K,V) subHighest();
    abstract TreeMapEntry!(K,V) subCeiling(K key);
    abstract TreeMapEntry!(K,V) subHigher(K key);
    abstract TreeMapEntry!(K,V) subFloor(K key);
    abstract TreeMapEntry!(K,V) subLower(K key);

    /** Returns ascending iterator from the perspective of this submap */
    // abstract Iterator!K keyIterator();

    // abstract Spliterator!K keySpliterator();

    /** Returns descending iterator from the perspective of this submap */
    // abstract Iterator!K descendingKeyIterator();


    // methods
    override bool opEquals(IObject o) {
        return opEquals(cast(Object) o);
    }
    
    override bool opEquals(Object o) {
        return super.opEquals(o);
    }

    override size_t toHash() @trusted nothrow {
        return super.toHash();
    }

    override string toString() {
        return super.toString();
    }    

    override bool isEmpty() {
        if(fromStart && toEnd)
            return m.isEmpty();
        else {
            TreeMapEntry!(K,V) n = absLowest();
            return n is null || tooHigh(n.key);
        }
    }

    override int size() { 
        if(fromStart && toEnd)
            return m.size();
        if(_size == -1 || sizeModCount != m.modCount)
            updateSize();
        return _size;
    }

    private void updateSize() {
        int s = 0;
        foreach(item; this) {
            s++;
        }
        _size = s;
    }

    final override bool containsKey(K key) {
        return inRange(key) && m.containsKey(key);
    }

    final override V put(K key, V value) {
        if (!inRange(key))
            throw new IllegalArgumentException("key out of range");
        // _size++;
        return m.put(key, value);
    }

    final override V get(K key) {
        return !inRange(key) ? null :  m.get(key);
    }

    final override V remove(K key) {
        // _size--;
        return !inRange(key) ? null : m.remove(key);
    }

    final MapEntry!(K,V) ceilingEntry(K key) {
        return exportEntry!(K,V)(subCeiling(key));
    }

    final K ceilingKey(K key) {
        return keyOrNull(subCeiling(key));
    }

    final MapEntry!(K,V) higherEntry(K key) {
        return exportEntry!(K,V)(subHigher(key));
    }

    final K higherKey(K key) {
        return keyOrNull(subHigher(key));
    }

    final MapEntry!(K,V) floorEntry(K key) {
        return exportEntry!(K,V)(subFloor(key));
    }

    final K floorKey(K key) {
        return keyOrNull(subFloor(key));
    }

    final MapEntry!(K,V) lowerEntry(K key) {
        return exportEntry!(K,V)(subLower(key));
    }

    final K lowerKey(K key) {
        return keyOrNull(subLower(key));
    }

    final K firstKey() {
        return key(subLowest());
    }

    final K lastKey() {
        return key(subHighest());
    }

    final MapEntry!(K,V) firstEntry() {
        return exportEntry!(K,V)(subLowest());
    }

    final MapEntry!(K,V) lastEntry() {
        return exportEntry!(K,V)(subHighest());
    }

    final MapEntry!(K,V) pollFirstEntry() {
        TreeMapEntry!(K,V) e = subLowest();
        MapEntry!(K,V) result = exportEntry!(K,V)(e);
        if (e !is null)
            m.deleteEntry(e);
        return result;
    }

    final MapEntry!(K,V) pollLastEntry() {
        TreeMapEntry!(K,V) e = subHighest();
        MapEntry!(K,V) result = exportEntry!(K,V)(e);
        if (e !is null)
            m.deleteEntry(e);
        return result;
    }

    // Views
    // NavigableMap!(K,V) descendingMapView;
    // EntrySetView entrySetView;
    // KeySet!(K, V) navigableKeySetView;

    // final NavigableSet!K navigableKeySet() {
    //     KeySet!(K, V) nksv = navigableKeySetView;
    //     return (nksv !is null) ? nksv :
    //         (navigableKeySetView = new TreeMap.KeySet!(K, V)(this));
    // }

    // final Set!K keySet() {
    //     return navigableKeySet();
    // }

    // NavigableSet!K descendingKeySet() {
    //     return descendingMap().navigableKeySet();
    // }

    alias subMap = NavigableMap!(K,V).subMap;
    alias headMap = NavigableMap!(K,V).headMap;
    alias tailMap = NavigableMap!(K,V).tailMap;

    final SortedMap!(K,V) subMap(K fromKey, K toKey) {
        return subMap(fromKey, true, toKey, false);
    }

    final SortedMap!(K,V) headMap(K toKey) {
        return headMap(toKey, false);
    }

    final SortedMap!(K,V) tailMap(K fromKey) {
        return tailMap(fromKey, true);
    }

    // View classes

    // abstract class EntrySetView : AbstractSet!(MapEntry!(K,V)) {
    //     private int _size = -1, sizeModCount;

    //     override int size() {
    //         if (fromStart && toEnd)
    //             return m.size();
    //         // if (_size == -1 || sizeModCount  !is  m.modCount) {
    //         //     sizeModCount = m.modCount;
    //         //     _size = 0;
    //         //     Iterator!K i = iterator();
    //         //     while (i.hasNext()) {
    //         //         _size++;
    //         //         i.next();
    //         //     }
    //         // }
    //         implementationMissing();
    //         return _size;
    //     }

    //     override bool isEmpty() {
    //         TreeMapEntry!(K,V) n = absLowest();
    //         return n is null || tooHigh(n.key);
    //     }

    //     override bool contains(MapEntry!(K,V) entry) {
    //         // MapEntry!(K,V) entry = cast(MapEntry!(K,V)) o;
    //         // if (!(o instanceof MapEntry))
    //         //     return false;
    //         K key = entry.getKey();
    //         if (!inRange(key))
    //             return false;
    //         TreeMapEntry!(K,V) node = m.getEntry(key);
    //         return node !is null &&
    //             valEquals(node.getValue(), entry.getValue());
    //     }

    //     bool remove(MapEntry!(K,V) entry) {
    //         // if (!(o instanceof MapEntry))
    //         //     return false;
    //         // MapEntry<?,?> entry = (MapEntry<?,?>) o;
    //         K key = entry.getKey();
    //         if (!inRange(key))
    //             return false;
    //         TreeMapEntry!(K,V) node = m.getEntry(key);
    //         if (node !is null && valEquals(node.getValue(),
    //                                     entry.getValue())) {
    //             m.deleteEntry(node);
    //             return true;
    //         }
    //         return false;
    //     }
    // }


    /**
     * Iterators for SubMaps
     */

    // see also: SubMapIterator
    mixin template SubMapInputRange() {
        TreeMapEntry!(K,V) lastReturned;
        TreeMapEntry!(K,V) next;
        K fenceKey;
        int expectedModCount;

        this(TreeMapEntry!(K,V) first,
                       TreeMapEntry!(K,V) fence) {
            expectedModCount = m.modCount;
            lastReturned = null;
            next = first;
            fenceKey = fence is null ? K.init : fence.key;
        }

        final bool empty() {
            return next is null || next.key == fenceKey;
        }

        final void popFront() {
            TreeMapEntry!(K,V) e = next;
            if (e is null || e.key == fenceKey) {
                throw new NoSuchElementException();
            }
            
            next = successor(e);
            lastReturned = e;
            // return e;
        }
    }

    final class KeyInputRange :  InputRange!K {
        mixin SubMapInputRange;

        final K front() @property { return next.key; }

        final K moveFront() @property { throw new NotSupportedException(); }
        
        int opApply(scope int delegate(K) dg) {
            if(dg is null)
                throw new NullPointerException();

            int result = 0;
            while(!empty()) {
                result = dg(next.key);
                // popFront();
                if(result != 0) return result;
                next = successor(next);
            }

            if (m.modCount  !=  expectedModCount)
                throw new ConcurrentModificationException();
            return result;
        }

        int opApply(scope int delegate(size_t, K) dg) {
            if(dg is null)
                throw new NullPointerException();

            int result = 0;
            size_t index = 0;
            while(!empty()) {
                result = dg(index++, next.key);
                if(result != 0) return result;
                next = successor(next);
            }

            if (m.modCount  !=  expectedModCount)
                throw new ConcurrentModificationException();

            return result;
        }
    }

    final class ValueInputRange :  InputRange!V {
        mixin SubMapInputRange;

        final V front() @property { return next.value; }

        final V moveFront() @property { throw new NotSupportedException(); }
        
        int opApply(scope int delegate(V) dg) {
            if(dg is null)
                throw new NullPointerException();

            int result = 0;
            while(!empty()) {
                result = dg(next.value);
                if(result != 0) return result;
                next = successor(next);
            }

            if (m.modCount  !=  expectedModCount)
                throw new ConcurrentModificationException();
            return result;
        }

        int opApply(scope int delegate(size_t, V) dg) {
            if(dg is null)
                throw new NullPointerException();

            int result = 0;
            size_t index = 0;
            while(!empty()) {
                result = dg(index++, next.value);
                if(result != 0) return result;
                next = successor(next);
            }

            if (m.modCount  !=  expectedModCount)
                throw new ConcurrentModificationException();

            return result;
        }
    }


    abstract class SubMapIterator(T) : Iterator!T {
        TreeMapEntry!(K,V) lastReturned;
        TreeMapEntry!(K,V) next;
        K fenceKey;
        int expectedModCount;

        this(TreeMapEntry!(K,V) first,
                       TreeMapEntry!(K,V) fence) {
            expectedModCount = m.modCount;
            lastReturned = null;
            next = first;
            fenceKey = fence is null ? K.init : fence.key;
        }

        final bool hasNext() {
            return next !is null && next.key  !is  fenceKey;
        }

        final TreeMapEntry!(K,V) nextEntry() {
            TreeMapEntry!(K,V) e = next;
            if (e is null || e.key == fenceKey)
                throw new NoSuchElementException();
            if (m.modCount  !is  expectedModCount)
                throw new ConcurrentModificationException();
            next = successor(e);
            lastReturned = e;
            return e;
        }

        final TreeMapEntry!(K,V) prevEntry() {
            TreeMapEntry!(K,V) e = next;
            if (e is null || e.key == fenceKey)
                throw new NoSuchElementException();
            if (m.modCount  !is  expectedModCount)
                throw new ConcurrentModificationException();
            next = predecessor(e);
            lastReturned = e;
            return e;
        }

        final void removeAscending() {
            if (lastReturned is null)
                throw new IllegalStateException();
            if (m.modCount  !is  expectedModCount)
                throw new ConcurrentModificationException();
            // deleted entries are replaced by their successors
            if (lastReturned.left !is null && lastReturned.right !is null)
                next = lastReturned;
            m.deleteEntry(lastReturned);
            lastReturned = null;
            expectedModCount = m.modCount;
        }

        final void removeDescending() {
            if (lastReturned is null)
                throw new IllegalStateException();
            if (m.modCount  !is  expectedModCount)
                throw new ConcurrentModificationException();
            m.deleteEntry(lastReturned);
            lastReturned = null;
            expectedModCount = m.modCount;
        }

    }

    final class SubMapEntryIterator : SubMapIterator!(MapEntry!(K,V)) {
        this(TreeMapEntry!(K,V) first,
                            TreeMapEntry!(K,V) fence) {
            super(first, fence);
        }
        MapEntry!(K,V) next() {
            return nextEntry();
        }
        void remove() {
            removeAscending();
        }
    }

    final class DescendingSubMapEntryIterator : SubMapIterator!(MapEntry!(K,V)) {
        this(TreeMapEntry!(K,V) last, TreeMapEntry!(K,V) fence) {
            super(last, fence);
        }

        MapEntry!(K,V) next() {
            return prevEntry();
        }
        void remove() {
            removeDescending();
        }
    }

    // Implement minimal Spliterator as KeySpliterator backup
    final class SubMapKeyIterator : SubMapIterator!K { // , Spliterator!K
        this(TreeMapEntry!(K,V) first,
                          TreeMapEntry!(K,V) fence) {
            super(first, fence);
        }
        K next() {
            return nextEntry().key;
        }
        void remove() {
            removeAscending();
        }
        Spliterator!K trySplit() {
            return null;
        }
        void forEachRemaining(Consumer!K action) {
            while (hasNext())
                action(next());
        }
        bool tryAdvance(Consumer!K action) {
            if (hasNext()) {
                action(next());
                return true;
            }
            return false;
        }
        long estimateSize() {
            return long.max;
        }
        int characteristics() {
            return SpliteratorCharacteristic.DISTINCT | SpliteratorCharacteristic.ORDERED |
                SpliteratorCharacteristic.SORTED;
        }
        final Comparator!K  getComparator() {
            return this.outer.comparator();
        }
    }

    final class DescendingSubMapKeyIterator : SubMapIterator!K { // , Spliterator!K
        this(TreeMapEntry!(K,V) last,
                                    TreeMapEntry!(K,V) fence) {
            super(last, fence);
        }
        K next() {
            return prevEntry().key;
        }
        void remove() {
            removeDescending();
        }
        Spliterator!K trySplit() {
            return null;
        }
        void forEachRemaining(Consumer!K action) {
            while (hasNext())
                action(next());
        }
        bool tryAdvance(Consumer!K action) {
            if (hasNext()) {
                action(next());
                return true;
            }
            return false;
        }
        long estimateSize() {
            return long.max;
        }
        // int characteristics() {
        //     return Spliterator.DISTINCT | Spliterator.ORDERED;
        // }
    }

    
}

/**
 * @serial include
 */
final class AscendingSubMap(K,V) : NavigableSubMap!(K,V) {
    // private static final long serialVersionUID = 912986545866124060L;

    this(TreeMap!(K,V) m,
                    bool fromStart, K lo, bool loInclusive,
                    bool toEnd,     K hi, bool hiInclusive) {
        super(m, fromStart, lo, loInclusive, toEnd, hi, hiInclusive);
    }

    Comparator!K comparator() {
        return m.comparator();
    }

    NavigableMap!(K,V) subMap(K fromKey, bool fromInclusive,
                                    K toKey,   bool toInclusive) {
        if (!inRange(fromKey, fromInclusive))
            throw new IllegalArgumentException("fromKey out of range");
        if (!inRange(toKey, toInclusive))
            throw new IllegalArgumentException("toKey out of range");
        return new AscendingSubMap!(K,V)(m,
                                     false, fromKey, fromInclusive,
                                     false, toKey,   toInclusive);
    }

    NavigableMap!(K,V) headMap(K toKey, bool inclusive) {
        if (!inRange(toKey, inclusive))
            throw new IllegalArgumentException("toKey out of range");
        return new AscendingSubMap!(K,V)(m,
                                     fromStart, lo,    loInclusive,
                                     false,     toKey, inclusive);
    }

    NavigableMap!(K,V) tailMap(K fromKey, bool inclusive) {
        if (!inRange(fromKey, inclusive))
            throw new IllegalArgumentException("fromKey out of range");
        return new AscendingSubMap!(K,V)(m,
                                     false, fromKey, inclusive,
                                     toEnd, hi,      hiInclusive);
    }

    // NavigableMap!(K,V) descendingMap() {
    //     NavigableMap!(K,V) mv = descendingMapView;
    //     return (mv !is null) ? mv :
    //         (descendingMapView =
    //          new DescendingSubMap!(K,V)(m,
    //                                 fromStart, lo, loInclusive,
    //                                 toEnd,     hi, hiInclusive));
    // }

    override InputRange!K byKey()    {
        return new KeyInputRange(absLowest(), absHighFence());
    }

    override InputRange!V byValue()    {
        return new ValueInputRange(absLowest(), absHighFence());
    }
    // override Iterator!K keyIterator() {
    //     return new SubMapKeyIterator(absLowest(), absHighFence());
    // }

    // Spliterator!K keySpliterator() {
    //     return new SubMapKeyIterator(absLowest(), absHighFence());
    // }

    // override Iterator!K descendingKeyIterator() {
    //     return new DescendingSubMapKeyIterator(absHighest(), absLowFence());
    // }


    override int opApply(scope int delegate(ref K, ref V) dg)  {
        if(dg is null)
            throw new NullPointerException();

        int result = 0;
        Iterator!(MapEntry!(K,V)) iterator = new SubMapEntryIterator(absLowest(), absHighFence());
        while(iterator.hasNext()) {
            TreeMapEntry!(K,V) e = cast(TreeMapEntry!(K,V)) iterator.next();
            result = dg(e.key, e.value);
            if(result != 0) return result;
        }

        return result;
    }
    
    override int opApply(scope int delegate(MapEntry!(K, V) entry) dg) {
        if(dg is null)
            throw new NullPointerException();

        int result = 0;
        Iterator!(MapEntry!(K,V)) iterator = new SubMapEntryIterator(absLowest(), absHighFence());
        while(iterator.hasNext()) {
            result = dg(iterator.next());
            if(result != 0) return result;
        }

        return result;
    }

    // final class AscendingEntrySetView : EntrySetView {
    //     Iterator!(MapEntry!(K,V)) iterator() {
    //         return new SubMapEntryIterator(absLowest(), absHighFence());
    //     }
    // }

    // Set!(MapEntry!(K,V)) entrySet() {
    //     EntrySetView es = entrySetView;
    //     return (es !is null) ? es : (entrySetView = new AscendingEntrySetView());
    // }

    override TreeMapEntry!(K,V) subLowest()       { return absLowest(); }
    override TreeMapEntry!(K,V) subHighest()      { return absHighest(); }
    override TreeMapEntry!(K,V) subCeiling(K key) { return absCeiling(key); }
    override TreeMapEntry!(K,V) subHigher(K key)  { return absHigher(key); }
    override TreeMapEntry!(K,V) subFloor(K key)   { return absFloor(key); }
    override TreeMapEntry!(K,V) subLower(K key)   { return absLower(key); }
}

/**
 * @serial include
 */
final class DescendingSubMap(K,V)  : NavigableSubMap!(K,V) {
    // private static final long serialVersionUID = 912986545866120460L;
    this(TreeMap!(K,V) m,
                    bool fromStart, K lo, bool loInclusive,
                    bool toEnd,     K hi, bool hiInclusive) {
        super(m, fromStart, lo, loInclusive, toEnd, hi, hiInclusive);

        // reverseComparator = Collections.reverseOrder(m._comparator);
    }

    private Comparator!K reverseComparator;

    Comparator!K comparator() {
        implementationMissing();
        return reverseComparator;
    }

    NavigableMap!(K,V) subMap(K fromKey, bool fromInclusive,
                                    K toKey,   bool toInclusive) {
        if (!inRange(fromKey, fromInclusive))
            throw new IllegalArgumentException("fromKey out of range");
        if (!inRange(toKey, toInclusive))
            throw new IllegalArgumentException("toKey out of range");
        return new DescendingSubMap!(K,V)(m,
                                      false, toKey,   toInclusive,
                                      false, fromKey, fromInclusive);
    }

    NavigableMap!(K,V) headMap(K toKey, bool inclusive) {
        if (!inRange(toKey, inclusive))
            throw new IllegalArgumentException("toKey out of range");
        return new DescendingSubMap!(K,V)(m,
                                      false, toKey, inclusive,
                                      toEnd, hi,    hiInclusive);
    }

    NavigableMap!(K,V) tailMap(K fromKey, bool inclusive) {
        if (!inRange(fromKey, inclusive))
            throw new IllegalArgumentException("fromKey out of range");
        return new DescendingSubMap!(K,V)(m,
                                      fromStart, lo, loInclusive,
                                      false, fromKey, inclusive);
    }

    // NavigableMap!(K,V) descendingMap() {
    //     NavigableMap!(K,V) mv = descendingMapView;
    //     return (mv !is null) ? mv :
    //         (descendingMapView =
    //          new AscendingSubMap!(K,V)(m,
    //                                fromStart, lo, loInclusive,
    //                                toEnd,     hi, hiInclusive));
    // }

    // override Iterator!K keyIterator() {
    //     return new DescendingSubMapKeyIterator(absHighest(), absLowFence());
    // }

    // override Spliterator!K keySpliterator() {
    //     return new DescendingSubMapKeyIterator(absHighest(), absLowFence());
    // }

    // override Iterator!K descendingKeyIterator() {
    //     return new SubMapKeyIterator(absLowest(), absHighFence());
    // }

    // final class DescendingEntrySetView : EntrySetView {
    //     Iterator!(MapEntry!(K,V)) iterator() {
    //         return new DescendingSubMapEntryIterator(absHighest(), absLowFence());
    //     }
    // }

    // Set!(MapEntry!(K,V)) entrySet() {
    //     EntrySetView es = entrySetView;
    //     return (es !is null) ? es : (entrySetView = new DescendingEntrySetView());
    // }

    override TreeMapEntry!(K,V) subLowest()       { return absHighest(); }
    override TreeMapEntry!(K,V) subHighest()      { return absLowest(); }
    override TreeMapEntry!(K,V) subCeiling(K key) { return absFloor(key); }
    override TreeMapEntry!(K,V) subHigher(K key)  { return absLower(key); }
    override TreeMapEntry!(K,V) subFloor(K key)   { return absCeiling(key); }
    override TreeMapEntry!(K,V) subLower(K key)   { return absHigher(key); }
}


// Little utilities

/**
* Returns the successor of the specified Entry, or null if no such.
*/
private TreeMapEntry!(K,V) successor(K,V)(TreeMapEntry!(K,V) t) {
    if (t is null)
        return null;
    else if (t.right !is null) {
        TreeMapEntry!(K,V) p = t.right;
        while (p.left !is null)
            p = p.left;
        return p;
    } else {
        TreeMapEntry!(K,V) p = t.parent;
        TreeMapEntry!(K,V) ch = t;
        while (p !is null && ch == p.right) {
            ch = p;
            p = p.parent;
        }
        return p;
    }
}

/**
* Returns the predecessor of the specified Entry, or null if no such.
*/
private TreeMapEntry!(K,V) predecessor(K,V)(TreeMapEntry!(K,V) t) {
    if (t is null)
        return null;
    else if (t.left !is null) {
        TreeMapEntry!(K,V) p = t.left;
        while (p.right !is null)
            p = p.right;
        return p;
    } else {
        TreeMapEntry!(K,V) p = t.parent;
        TreeMapEntry!(K,V) ch = t;
        while (p !is null && ch == p.left) {
            ch = p;
            p = p.parent;
        }
        return p;
    }
}


/**
* Test two values for equality.  Differs from o1.equals(o2) only in
* that it copes with {@code null} o1 properly.
*/
private bool valEquals(V)(V o1, V o2) {
    // return (o1 is null ? o2 is null : o1.equals(o2));
    return o1 == o2;
}

/**
* Return SimpleImmutableEntry for entry, or null if null
*/
private MapEntry!(K,V) exportEntry(K,V)(TreeMapEntry!(K,V) e) {
    return (e is null) ? null :
        new SimpleImmutableEntry!(K,V)(e);
}

/**
* Return key for entry, or null if null
*/
private K keyOrNull(K,V)(TreeMapEntry!(K,V) e) {        
    return (e is null) ? K.init : e.key;
}

/**
* Returns the key corresponding to the specified Entry.
* @throws NoSuchElementException if the Entry is null
*/
private K key(K, V)(TreeMapEntry!(K,V) e) {
    if (e is null)
        throw new NoSuchElementException();
    return e.key;
}
