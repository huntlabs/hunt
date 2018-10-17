module hunt.container.LinkedHashMap;

import hunt.container.AbstractCollection;
import hunt.container.AbstractMap;
import hunt.container.HashMap;
import hunt.container.Map;

import hunt.lang.exception;

import std.range;

/**
 * <p>Hash table and linked list implementation of the <tt>Map</tt> interface,
 * with predictable iteration order.  This implementation differs from
 * <tt>HashMap</tt> in that it maintains a doubly-linked list running through
 * all of its entries.  This linked list defines the iteration ordering,
 * which is normally the order in which keys were inserted into the map
 * (<i>insertion-order</i>).  Note that insertion order is not affected
 * if a key is <i>re-inserted</i> into the map.  (A key <tt>k</tt> is
 * reinserted into a map <tt>m</tt> if <tt>m.put(k, v)</tt> is invoked when
 * <tt>m.containsKey(k)</tt> would return <tt>true</tt> immediately prior to
 * the invocation.)
 *
 * <p>This implementation spares its clients from the unspecified, generally
 * chaotic ordering provided by {@link HashMap} (and {@link Hashtable}),
 * without incurring the increased cost associated with {@link TreeMap}.  It
 * can be used to produce a copy of a map that has the same order as the
 * original, regardless of the original map's implementation:
 * <pre>
 *     void foo(Map m) {
 *         Map copy = new LinkedHashMap(m);
 *         ...
 *     }
 * </pre>
 * This technique is particularly useful if a module takes a map on input,
 * copies it, and later returns results whose order is determined by that of
 * the copy.  (Clients generally appreciate having things returned in the same
 * order they were presented.)
 *
 * <p>A special {@link #LinkedHashMap(int,float,bool) constructor} is
 * provided to create a linked hash map whose order of iteration is the order
 * in which its entries were last accessed, from least-recently accessed to
 * most-recently (<i>access-order</i>).  This kind of map is well-suited to
 * building LRU caches.  Invoking the {@code put}, {@code putIfAbsent},
 * {@code get}, {@code getOrDefault}, {@code compute}, {@code computeIfAbsent},
 * {@code computeIfPresent}, or {@code merge} methods results
 * in an access to the corresponding entry (assuming it exists after the
 * invocation completes). The {@code replace} methods only result in an access
 * of the entry if the value is replaced.  The {@code putAll} method generates one
 * entry access for each mapping in the specified map, in the order that
 * key-value mappings are provided by the specified map's entry set iterator.
 * <i>No other methods generate entry accesses.</i>  In particular, operations
 * on collection-views do <i>not</i> affect the order of iteration of the
 * backing map.
 *
 * <p>The {@link #removeEldestEntry(MapEntry)} method may be overridden to
 * impose a policy for removing stale mappings automatically when new mappings
 * are added to the map.
 *
 * <p>This class provides all of the optional <tt>Map</tt> operations, and
 * permits null elements.  Like <tt>HashMap</tt>, it provides constant-time
 * performance for the basic operations (<tt>add</tt>, <tt>contains</tt> and
 * <tt>remove</tt>), assuming the hash function disperses elements
 * properly among the buckets.  Performance is likely to be just slightly
 * below that of <tt>HashMap</tt>, due to the added expense of maintaining the
 * linked list, with one exception: Iteration over the collection-views
 * of a <tt>LinkedHashMap</tt> requires time proportional to the <i>size</i>
 * of the map, regardless of its capacity.  Iteration over a <tt>HashMap</tt>
 * is likely to be more expensive, requiring time proportional to its
 * <i>capacity</i>.
 *
 * <p>A linked hash map has two parameters that affect its performance:
 * <i>initial capacity</i> and <i>load factor</i>.  They are defined precisely
 * as for <tt>HashMap</tt>.  Note, however, that the penalty for choosing an
 * excessively high value for initial capacity is less severe for this class
 * than for <tt>HashMap</tt>, as iteration times for this class are unaffected
 * by capacity.
 *
 * <p><strong>Note that this implementation is not synchronized.</strong>
 * If multiple threads access a linked hash map concurrently, and at least
 * one of the threads modifies the map structurally, it <em>must</em> be
 * synchronized externally.  This is typically accomplished by
 * synchronizing on some object that naturally encapsulates the map.
 *
 * If no such object exists, the map should be "wrapped" using the
 * {@link Collections#synchronizedMap Collections.synchronizedMap}
 * method.  This is best done at creation time, to prevent accidental
 * unsynchronized access to the map:<pre>
 *   Map m = Collections.synchronizedMap(new LinkedHashMap(...));</pre>
 *
 * A structural modification is any operation that adds or deletes one or more
 * mappings or, in the case of access-ordered linked hash maps, affects
 * iteration order.  In insertion-ordered linked hash maps, merely changing
 * the value associated with a key that is already contained in the map is not
 * a structural modification.  <strong>In access-ordered linked hash maps,
 * merely querying the map with <tt>get</tt> is a structural modification.
 * </strong>)
 *
 * <p>The iterators returned by the <tt>iterator</tt> method of the collections
 * returned by all of this class's collection view methods are
 * <em>fail-fast</em>: if the map is structurally modified at any time after
 * the iterator is created, in any way except through the iterator's own
 * <tt>remove</tt> method, the iterator will throw a {@link
 * ConcurrentModificationException}.  Thus, in the face of concurrent
 * modification, the iterator fails quickly and cleanly, rather than risking
 * arbitrary, non-deterministic behavior at an undetermined time in the future.
 *
 * <p>Note that the fail-fast behavior of an iterator cannot be guaranteed
 * as it is, generally speaking, impossible to make any hard guarantees in the
 * presence of unsynchronized concurrent modification.  Fail-fast iterators
 * throw <tt>ConcurrentModificationException</tt> on a best-effort basis.
 * Therefore, it would be wrong to write a program that depended on this
 * exception for its correctness:   <i>the fail-fast behavior of iterators
 * should be used only to detect bugs.</i>
 *
 * <p>The spliterators returned by the spliterator method of the collections
 * returned by all of this class's collection view methods are
 * <em><a href="Spliterator.html#binding">late-binding</a></em>,
 * <em>fail-fast</em>, and additionally report {@link Spliterator#ORDERED}.
 *
 * <p>This class is a member of the
 * <a href="{@docRoot}/../technotes/guides/collections/index.html">
 * Java Collections Framework</a>.
 *
 * @implNote
 * The spliterators returned by the spliterator method of the collections
 * returned by all of this class's collection view methods are created from
 * the iterators of the corresponding collections.
 *
 * @param (K) the type of keys maintained by this map
 * @param (V) the type of mapped values
 *
 * @author  Josh Bloch
 * @see     Object#hashCode()
 * @see     Collection
 * @see     Map
 * @see     HashMap
 * @see     TreeMap
 * @see     Hashtable
 * @since   1.4
 */
class LinkedHashMap(K, V) : HashMap!(K, V)
{
    /*
     * Implementation note.  A previous version of this class was
     * internally structured a little differently. Because superclass
     * HashMap now uses trees for some of its nodes, class
     * LinkedHashMapEntry is now treated as intermediary node class
     * that can also be converted to tree form. The name of this
     * class, LinkedHashMapEntry, is confusing in several ways in its
     * current context, but cannot be changed.  Otherwise, even though
     * it is not exported outside this package, some existing source
     * code is known to have relied on a symbol resolution corner case
     * rule in calls to removeEldestEntry that suppressed compilation
     * errors due to ambiguous usages. So, we keep the name to
     * preserve unmodified compilability.
     *
     * The changes in node classes also require using two fields
     * (head, tail) rather than a pointer to a header node to maintain
     * the doubly-linked before/after list. This class also
     * previously used a different style of callback methods upon
     * access, insertion, and removal.
     */


    // private static final long serialVersionUID = 3801124242820219131L;

    /**
     * The head (eldest) of the doubly linked list.
     */
    LinkedHashMapEntry!(K, V)head;

    /**
     * The tail (youngest) of the doubly linked list.
     */
    LinkedHashMapEntry!(K, V)tail;

    /**
     * The iteration ordering method for this linked hash map: <tt>true</tt>
     * for access-order, <tt>false</tt> for insertion-order.
     *
     * @serial
     */
    bool accessOrder;

    // internal utilities

    // link at the end of list
    private void linkNodeLast(LinkedHashMapEntry!(K, V)p) {
        LinkedHashMapEntry!(K, V)last = tail;
        tail = p;
        if (last is null)
            head = p;
        else {
            p.before = last;
            last.after = p;
        }
    }

    // apply src's links to dst
    private void transferLinks(LinkedHashMapEntry!(K, V)src,
                               LinkedHashMapEntry!(K, V)dst) {
        LinkedHashMapEntry!(K, V)b = dst.before = src.before;
        LinkedHashMapEntry!(K, V)a = dst.after = src.after;
        if (b is null)
            head = dst;
        else
            b.after = dst;
        if (a is null)
            tail = dst;
        else
            a.before = dst;
    }

    // overrides of HashMap hook methods

    override void reinitialize() {
        super.reinitialize();
        head = tail = null;
    }

    override HashMapNode!(K, V) newNode(size_t hash, K key, V value, HashMapNode!(K, V) e) {
        LinkedHashMapEntry!(K, V) p = new LinkedHashMapEntry!(K, V)(hash, key, value, e);
        linkNodeLast(p);
        return p;
    }

    override HashMapNode!(K, V) replacementNode(HashMapNode!(K, V) p, HashMapNode!(K, V) next) {
        LinkedHashMapEntry!(K, V) q = cast(LinkedHashMapEntry!(K, V))p;
        LinkedHashMapEntry!(K, V) t = new LinkedHashMapEntry!(K, V)(q.hash, q.key, q.value, next);
        transferLinks(q, t);
        return t;
    }

    override TreeNode!(K, V) newTreeNode(size_t hash, K key, V value, HashMapNode!(K, V) next) {
        TreeNode!(K, V) p = new TreeNode!(K, V)(hash, key, value, next);
        linkNodeLast(p);
        return p;
    }

    override TreeNode!(K, V) replacementTreeNode(HashMapNode!(K, V) p, HashMapNode!(K, V) next) {
        LinkedHashMapEntry!(K, V)q = cast(LinkedHashMapEntry!(K, V))p;
        TreeNode!(K, V) t = new TreeNode!(K, V)(q.hash, q.key, q.value, next);
        transferLinks(q, t);
        return t;
    }

    override void afterNodeRemoval(HashMapNode!(K, V) e) { // unlink
        LinkedHashMapEntry!(K, V)p =
            cast(LinkedHashMapEntry!(K, V))e, b = p.before, a = p.after;
        p.before = p.after = null;
        if (b is null)
            head = a;
        else
            b.after = a;
        if (a is null)
            tail = b;
        else
            a.before = b;
    }

    override void afterNodeInsertion(bool evict) { // possibly remove eldest
        LinkedHashMapEntry!(K, V) first;
        if (evict && (first = head) !is null && removeEldestEntry(first)) {
            K key = first.key;
            removeNode(hash(key), key, null, false, true);
        }
    }

    override void afterNodeAccess(HashMapNode!(K, V) e) { // move node to last
        LinkedHashMapEntry!(K, V)last;
        if (accessOrder && (last = tail) != e) {
            LinkedHashMapEntry!(K, V)p =
                cast(LinkedHashMapEntry!(K, V))e, b = p.before, a = p.after;
            p.after = null;
            if (b is null)
                head = a;
            else
                b.after = a;
            if (a !is null)
                a.before = b;
            else
                last = b;
            if (last is null)
                head = p;
            else {
                p.before = last;
                last.after = p;
            }
            tail = p;
            ++modCount;
        }
    }

    // void internalWriteEntries(java.io.ObjectOutputStream s) {
    //     for (LinkedHashMapEntry!(K, V)e = head; e !is null; e = e.after) {
    //         s.writeObject(e.key);
    //         s.writeObject(e.value);
    //     }
    // }

    /**
     * Constructs an empty insertion-ordered <tt>LinkedHashMap</tt> instance
     * with the specified initial capacity and load factor.
     *
     * @param  initialCapacity the initial capacity
     * @param  loadFactor      the load factor
     * @throws IllegalArgumentException if the initial capacity is negative
     *         or the load factor is nonpositive
     */
    this(int initialCapacity, float loadFactor) {
        super(initialCapacity, loadFactor);
        accessOrder = false;
    }

    /**
     * Constructs an empty insertion-ordered <tt>LinkedHashMap</tt> instance
     * with the specified initial capacity and a default load factor (0.75).
     *
     * @param  initialCapacity the initial capacity
     * @throws IllegalArgumentException if the initial capacity is negative
     */
    this(int initialCapacity) {
        super(initialCapacity);
        accessOrder = false;
    }

    /**
     * Constructs an empty insertion-ordered <tt>LinkedHashMap</tt> instance
     * with the default initial capacity (16) and load factor (0.75).
     */
    this() {
        super();
        accessOrder = false;
    }

    /**
     * Constructs an insertion-ordered <tt>LinkedHashMap</tt> instance with
     * the same mappings as the specified map.  The <tt>LinkedHashMap</tt>
     * instance is created with a default load factor (0.75) and an initial
     * capacity sufficient to hold the mappings in the specified map.
     *
     * @param  m the map whose mappings are to be placed in this map
     * @throws NullPointerException if the specified map is null
     */
    this(Map!(K, V) m) {
        super();
        accessOrder = false;
        putMapEntries(m, false);
    }

    /**
     * Constructs an empty <tt>LinkedHashMap</tt> instance with the
     * specified initial capacity, load factor and ordering mode.
     *
     * @param  initialCapacity the initial capacity
     * @param  loadFactor      the load factor
     * @param  accessOrder     the ordering mode - <tt>true</tt> for
     *         access-order, <tt>false</tt> for insertion-order
     * @throws IllegalArgumentException if the initial capacity is negative
     *         or the load factor is nonpositive
     */
    this(int initialCapacity,
                         float loadFactor,
                         bool accessOrder) {
        super(initialCapacity, loadFactor);
        this.accessOrder = accessOrder;
    }


    /**
     * Returns <tt>true</tt> if this map maps one or more keys to the
     * specified value.
     *
     * @param value value whose presence in this map is to be tested
     * @return <tt>true</tt> if this map maps one or more keys to the
     *         specified value
     */
    override bool containsValue(V value) {
        for (LinkedHashMapEntry!(K, V)e = head; e !is null; e = e.after) {
            V v = e.value;
            if (v == value) //  || (value !is null && value.equals(v))
                return true;
        }
        return false;
    }

    /**
     * Returns the value to which the specified key is mapped,
     * or {@code null} if this map contains no mapping for the key.
     *
     * <p>More formally, if this map contains a mapping from a key
     * {@code k} to a value {@code v} such that {@code (key==null ? k==null :
     * key.equals(k))}, then this method returns {@code v}; otherwise
     * it returns {@code null}.  (There can be at most one such mapping.)
     *
     * <p>A return value of {@code null} does not <i>necessarily</i>
     * indicate that the map contains no mapping for the key; it's also
     * possible that the map explicitly maps the key to {@code null}.
     * The {@link #containsKey containsKey} operation may be used to
     * distinguish these two cases.
     */
    override V get(K key) {
        HashMapNode!(K, V) e = getNode(hash(key), key);
        if (e is null)
            return null;
        if (accessOrder)
            afterNodeAccess(e);
        return e.value;
    }

    /**
     * {@inheritDoc}
     */
    override V getOrDefault(K key, V defaultValue) {
       HashMapNode!(K, V) e;
       if ((e = getNode(hash(key), key)) is null)
           return defaultValue;
       if (accessOrder)
           afterNodeAccess(e);
       return e.value;
   }

    /**
     * {@inheritDoc}
     */
    override void clear() {
        super.clear();
        head = tail = null;
    }

    /**
     * Returns <tt>true</tt> if this map should remove its eldest entry.
     * This method is invoked by <tt>put</tt> and <tt>putAll</tt> after
     * inserting a new entry into the map.  It provides the implementor
     * with the opportunity to remove the eldest entry each time a new one
     * is added.  This is useful if the map represents a cache: it allows
     * the map to reduce memory consumption by deleting stale entries.
     *
     * <p>Sample use: this override will allow the map to grow up to 100
     * entries and then delete the eldest entry each time a new entry is
     * added, maintaining a steady state of 100 entries.
     * <pre>
     *     private static final int MAX_ENTRIES = 100;
     *
     *     protected bool removeEldestEntry(MapEntry eldest) {
     *        return size() &gt; MAX_ENTRIES;
     *     }
     * </pre>
     *
     * <p>This method typically does not modify the map in any way,
     * instead allowing the map to modify itself as directed by its
     * return value.  It <i>is</i> permitted for this method to modify
     * the map directly, but if it does so, it <i>must</i> return
     * <tt>false</tt> (indicating that the map should not attempt any
     * further modification).  The effects of returning <tt>true</tt>
     * after modifying the map from within this method are unspecified.
     *
     * <p>This implementation merely returns <tt>false</tt> (so that this
     * map acts like a normal map - the eldest element is never removed).
     *
     * @param    eldest The least recently inserted entry in the map, or if
     *           this is an access-ordered map, the least recently accessed
     *           entry.  This is the entry that will be removed it this
     *           method returns <tt>true</tt>.  If the map was empty prior
     *           to the <tt>put</tt> or <tt>putAll</tt> invocation resulting
     *           in this invocation, this will be the entry that was just
     *           inserted; in other words, if the map contains a single
     *           entry, the eldest entry is also the newest.
     * @return   <tt>true</tt> if the eldest entry should be removed
     *           from the map; <tt>false</tt> if it should be retained.
     */
    protected bool removeEldestEntry(MapEntry!(K, V) eldest) {
        return false;
    }

    /**
     * Returns a {@link Set} view of the keys contained in this map.
     * The set is backed by the map, so changes to the map are
     * reflected in the set, and vice-versa.  If the map is modified
     * while an iteration over the set is in progress (except through
     * the iterator's own <tt>remove</tt> operation), the results of
     * the iteration are undefined.  The set supports element removal,
     * which removes the corresponding mapping from the map, via the
     * <tt>Iterator.remove</tt>, <tt>Set.remove</tt>,
     * <tt>removeAll</tt>, <tt>retainAll</tt>, and <tt>clear</tt>
     * operations.  It does not support the <tt>add</tt> or <tt>addAll</tt>
     * operations.
     * Its {@link Spliterator} typically provides faster sequential
     * performance but much poorer parallel performance than that of
     * {@code HashMap}.
     *
     * @return a set view of the keys contained in this map
     */
    // Set!(K) keySet() {
    //     Set!(K) ks = keySet;
    //     if (ks is null) {
    //         ks = new LinkedKeySet();
    //         keySet = ks;
    //     }
    //     return ks;
    // }

    // final class LinkedKeySet : AbstractSet!(K) {
    //     final int size()                 { return size; }
    //     final void clear()               { LinkedHashMap.this.clear(); }
    //     final Iterator!(K) iterator() {
    //         return new LinkedKeyIterator();
    //     }
    //     final bool contains(Object o) { return containsKey(o); }
    //     final bool remove(Object key) {
    //         return removeNode(hash(key), key, null, false, true) !is null;
    //     }
    //     final Spliterator!(K) spliterator()  {
    //         return Spliterators.spliterator(this, Spliterator.SIZED |
    //                                         Spliterator.ORDERED |
    //                                         Spliterator.DISTINCT);
    //     }
    //     final void forEach(Consumer<K> action) {
    //         if (action is null)
    //             throw new NullPointerException();
    //         int mc = modCount;
    //         for (LinkedHashMapEntry!(K, V)e = head; e !is null; e = e.after)
    //             action.accept(e.key);
    //         if (modCount != mc)
    //             throw new ConcurrentModificationException();
    //     }
    // }

    /**
     * Returns a {@link Collection} view of the values contained in this map.
     * The collection is backed by the map, so changes to the map are
     * reflected in the collection, and vice-versa.  If the map is
     * modified while an iteration over the collection is in progress
     * (except through the iterator's own <tt>remove</tt> operation),
     * the results of the iteration are undefined.  The collection
     * supports element removal, which removes the corresponding
     * mapping from the map, via the <tt>Iterator.remove</tt>,
     * <tt>Collection.remove</tt>, <tt>removeAll</tt>,
     * <tt>retainAll</tt> and <tt>clear</tt> operations.  It does not
     * support the <tt>add</tt> or <tt>addAll</tt> operations.
     * Its {@link Spliterator} typically provides faster sequential
     * performance but much poorer parallel performance than that of
     * {@code HashMap}.
     *
     * @return a view of the values contained in this map
     */
    // Collection!(V) values() {
    //     Collection!(V) vs = values;
    //     if (vs is null) {
    //         vs = new LinkedValues();
    //         values = vs;
    //     }
    //     return vs;
    // }

    // final class LinkedValues : AbstractCollection!(V) {
    //     final override int size()                 { return _size; }
    //     final override void clear()               { this.outer.clear(); }
    //     // final Iterator!(V) iterator() {
    //     //     return new LinkedValueIterator();
    //     // }
    //     final bool contains(Object o) { return containsValue(o); }
    //     // final Spliterator!(V) spliterator() {
    //     //     return Spliterators.spliterator(this, Spliterator.SIZED |
    //     //                                     Spliterator.ORDERED);
    //     // }
    //     // final void forEach(Consumer<V> action) {
    //     //     if (action is null)
    //     //         throw new NullPointerException();
    //     //     int mc = modCount;
    //     //     for (LinkedHashMapEntry!(K, V)e = head; e !is null; e = e.after)
    //     //         action.accept(e.value);
    //     //     if (modCount != mc)
    //     //         throw new ConcurrentModificationException();
    //     // }
    // }

    /**
     * Returns a {@link Set} view of the mappings contained in this map.
     * The set is backed by the map, so changes to the map are
     * reflected in the set, and vice-versa.  If the map is modified
     * while an iteration over the set is in progress (except through
     * the iterator's own <tt>remove</tt> operation, or through the
     * <tt>setValue</tt> operation on a map entry returned by the
     * iterator) the results of the iteration are undefined.  The set
     * supports element removal, which removes the corresponding
     * mapping from the map, via the <tt>Iterator.remove</tt>,
     * <tt>Set.remove</tt>, <tt>removeAll</tt>, <tt>retainAll</tt> and
     * <tt>clear</tt> operations.  It does not support the
     * <tt>add</tt> or <tt>addAll</tt> operations.
     * Its {@link Spliterator} typically provides faster sequential
     * performance but much poorer parallel performance than that of
     * {@code HashMap}.
     *
     * @return a set view of the mappings contained in this map
     */
    // Set!(MapEntry!(K, V)) entrySet() {
    //     Set!(MapEntry!(K, V)) es;
    //     return (es = entrySet) is null ? (entrySet = new LinkedEntrySet()) : es;
    // }

    // final class LinkedEntrySet : AbstractSet!(MapEntry!(K, V)) {
    //     final int size()                 { return size; }
    //     final void clear()               { this.outer.clear(); }
    //     final Iterator!(MapEntry!(K, V)) iterator() {
    //         return new LinkedEntryIterator();
    //     }
    //     // final bool contains(Object o) {
    //     //     if (!(o instanceof MapEntry))
    //     //         return false;
    //     //     MapEntry<?,?> e = (MapEntry<?,?>) o;
    //     //     Object key = e.getKey();
    //     //     HashMapNode!(K, V) candidate = getNode(hash(key), key);
    //     //     return candidate !is null && candidate.equals(e);
    //     // }
    //     // final bool remove(Object o) {
    //     //     if (o instanceof MapEntry) {
    //     //         MapEntry<?,?> e = (MapEntry<?,?>) o;
    //     //         Object key = e.getKey();
    //     //         Object value = e.getValue();
    //     //         return removeNode(hash(key), key, value, true, true) !is null;
    //     //     }
    //     //     return false;
    //     // }
    //     // final Spliterator!(MapEntry!(K, V)) spliterator() {
    //     //     return Spliterators.spliterator(this, Spliterator.SIZED |
    //     //                                     Spliterator.ORDERED |
    //     //                                     Spliterator.DISTINCT);
    //     // }
    //     // final void forEach(Consumer<MapEntry!(K, V)> action) {
    //     //     if (action is null)
    //     //         throw new NullPointerException();
    //     //     int mc = modCount;
    //     //     for (LinkedHashMapEntry!(K, V)e = head; e !is null; e = e.after)
    //     //         action.accept(e);
    //     //     if (modCount != mc)
    //     //         throw new ConcurrentModificationException();
    //     // }
    // }

    // Map overrides

    // void replaceAll(BiFunction<K, V, ? : V> function) {
    //     if (function is null)
    //         throw new NullPointerException();
    //     int mc = modCount;
    //     for (LinkedHashMapEntry!(K, V)e = head; e !is null; e = e.after)
    //         e.value = function.apply(e.key, e.value);
    //     if (modCount != mc)
    //         throw new ConcurrentModificationException();
    // }

    // Iterators

    override int opApply(scope int delegate(ref K, ref V) dg)
    {
        if(dg is null)
            throw new NullPointerException("");

        int result = 0;
        int mc = modCount;
        for (LinkedHashMapEntry!(K, V)e = head; e !is null; e = e.after)
        {
            result = dg(e.key, e.value);
            if(result != 0) return result;
        }

        if(modCount != mc)
            throw new ConcurrentModificationException();

        return result;
    }

    override int opApply(scope int delegate(MapEntry!(K, V) entry) dg)
    {
        if(dg is null)
            throw new NullPointerException();

        int result = 0;
        int mc = modCount;
        for (LinkedHashMapEntry!(K, V)e = head; e !is null; e = e.after)
        {
            result = dg(e);
            if(result != 0) return result;
        }

        if(modCount != mc)
            throw new ConcurrentModificationException();

        return result;
    }

    override InputRange!K byKey()
    {
        return new KeyInputRange();
    }

    override InputRange!V byValue()
    {
        return new ValueInputRange();
    }

    mixin template LinkedHashMapIterator() {
        private LinkedHashMapEntry!(K, V) next;
        private LinkedHashMapEntry!(K, V) current;
        private int expectedModCount;

        this() {
            next = head;
            expectedModCount = modCount;
            current = null;
        }

        final bool empty() {
            return next is null;
        }

        void popFront()
        {
            LinkedHashMapEntry!(K, V) e = next;
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
            if (e is null)
                throw new NoSuchElementException();
            current = e;
            next = e.after;
            // return e;
        }
    }

    final class KeyInputRange :  InputRange!K {
        mixin LinkedHashMapIterator;

        final K front() @property { return next.key; }

        // https://forum.dlang.org/thread/amzthhonuozlobghqqgk@forum.dlang.org?page=1
        // https://issues.dlang.org/show_bug.cgi?id=18036
        final K moveFront() @property { throw new NotSupportedException(); }
        
        int opApply(scope int delegate(K) dg) {
            if(dg is null)
                throw new NullPointerException();

            int result = 0;
            int mc = modCount;
            for (LinkedHashMapEntry!(K, V)e = head; e !is null; e = e.after)
            {
                result = dg(e.key);
                if(result != 0) return result;
            }

            if(modCount != mc)
                throw new ConcurrentModificationException();

            return result;
        }

        int opApply(scope int delegate(size_t, K) dg) {
            if(dg is null)
                throw new NullPointerException();

            int result = 0;
            int mc = modCount;
            size_t index = 0;
            for (LinkedHashMapEntry!(K, V)e = head; e !is null; e = e.after)
            {
                result = dg(index++, e.key);
                if(result != 0) return result;
            }

            if(modCount != mc)
                throw new ConcurrentModificationException();

            return result;
        }
    }
    
    final class ValueInputRange :  InputRange!V {
        mixin LinkedHashMapIterator;

        final V front() @property { return next.value; }

        final V moveFront() @property { throw new NotSupportedException(); }
        
        int opApply(scope int delegate(V) dg) {
            if(dg is null)
                throw new NullPointerException();

            int result = 0;
            int mc = modCount;
            for (LinkedHashMapEntry!(K, V)e = head; e !is null; e = e.after)
            {
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
            for (LinkedHashMapEntry!(K, V)e = head; e !is null; e = e.after) {
                result = dg(index++, e.value);
                if(result != 0) return result;
            }

            if(modCount != mc)
                throw new ConcurrentModificationException();

            return result;
        }
    }


}

