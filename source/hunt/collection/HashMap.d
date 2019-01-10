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

module hunt.collection.HashMap;

import hunt.collection.AbstractMap;
import hunt.collection.Map;
import hunt.collection.Iterator;

import hunt.Exceptions;
import hunt.Object;
import hunt.text.StringBuilder;

import std.algorithm;
import std.conv;
import std.format: format;
import std.math;
import std.range;
import std.traits;

/**
*/
class HashMap(K,V) : AbstractMap!(K,V) {

    // private enum long serialVersionUID = 362498820763181265L;

    /*
     * Implementation notes.
     *
     * This map usually acts as a binned (bucketed) hash table, but
     * when bins get too large, they are transformed into bins of
     * TreeNodes, each structured similarly to those in
     * java.util.TreeMap. Most methods try to use normal bins, but
     * relay to TreeNode methods when applicable (simply by checking
     * instanceof a node).  Bins of TreeNodes may be traversed and
     * used like any others, but additionally support faster lookup
     * when overpopulated. However, since the vast majority of bins in
     * normal use are not overpopulated, checking for existence of
     * tree bins may be delayed in the course of table methods.
     *
     * Tree bins (i.e., bins whose elements are all TreeNodes) are
     * ordered primarily by toHash, but in the case of ties, if two
     * elements are of the same "class C implements Comparable<C>",
     * type then their compareTo method is used for ordering. (We
     * conservatively check generic types via reflection to validate
     * this -- see method comparableClassFor).  The added complexity
     * of tree bins is worthwhile in providing worst-case O(log n)
     * operations when keys either have distinct hashes or are
     * orderable, Thus, performance degrades gracefully under
     * accidental or malicious usages in which toHash() methods
     * return values that are poorly distributed, as well as those in
     * which many keys share a toHash, so long as they are also
     * Comparable. (If neither of these apply, we may waste about a
     * factor of two in time and space compared to taking no
     * precautions. But the only known cases stem from poor user
     * programming practices that are already so slow that this makes
     * little difference.)
     *
     * Because TreeNodes are about twice the size of regular nodes, we
     * use them only when bins contain enough nodes to warrant use
     * (see TREEIFY_THRESHOLD). And when they become too small (due to
     * removal or resizing) they are converted back to plain bins.  In
     * usages with well-distributed user hashCodes, tree bins are
     * rarely used.  Ideally, under random hashCodes, the frequency of
     * nodes in bins follows a Poisson distribution
     * (http://en.wikipedia.org/wiki/Poisson_distribution) with a
     * parameter of about 0.5 on average for the default resizing
     * threshold of 0.75, although with a large variance because of
     * resizing granularity. Ignoring variance, the expected
     * occurrences of list size k are (exp(-0.5) * pow(0.5, k) /
     * factorial(k)). The first values are:
     *
     * 0:    0.60653066
     * 1:    0.30326533
     * 2:    0.07581633
     * 3:    0.01263606
     * 4:    0.00157952
     * 5:    0.00015795
     * 6:    0.00001316
     * 7:    0.00000094
     * 8:    0.00000006
     * more: less than 1 in ten million
     *
     * The root of a tree bin is normally its first node.  However,
     * sometimes (currently only upon Iterator.remove), the root might
     * be elsewhere, but can be recovered following parent links
     * (method TreeNode.root()).
     *
     * All applicable internal methods accept a hash code as an
     * argument (as normally supplied from a method), allowing
     * them to call each other without recomputing user hashCodes.
     * Most internal methods also accept a "tab" argument, that is
     * normally the current table, but may be a new or old one when
     * resizing or converting.
     *
     * When bin lists are treeified, split, or untreeified, we keep
     * them in the same relative access/traversal order (i.e., field
     * Node.next) to better preserve locality, and to slightly
     * simplify handling of splits and traversals that invoke
     * iterator.remove. When using comparators on insertion, to keep a
     * total ordering (or as close as is required here) across
     * rebalancings, we compare classes and identityHashCodes as
     * tie-breakers.
     *
     * The use and transitions among plain vs tree modes is
     * complicated by the existence of subclass LinkedHashMap. See
     * below for hook methods defined to be invoked upon insertion,
     * removal and access that allow LinkedHashMap internals to
     * otherwise remain independent of these mechanics. (This also
     * requires that a map instance be passed to some utility methods
     * that may create new nodes.)
     *
     * The concurrent-programming-like SSA-based coding style helps
     * avoid aliasing errors amid all of the twisty pointer operations.
     */

    /**
     * The default initial capacity - MUST be a power of two.
     */
    enum int DEFAULT_INITIAL_CAPACITY = 1 << 4; // aka 16

    /**
     * The maximum capacity, used if a higher value is implicitly specified
     * by either of the constructors with arguments.
     * MUST be a power of two <= 1<<30.
     */
    enum int MAXIMUM_CAPACITY = 1 << 30;

    /**
     * The load factor used when none specified in constructor.
     */
    enum float DEFAULT_LOAD_FACTOR = 0.75f;

    /**
     * The bin count threshold for using a tree rather than list for a
     * bin.  Bins are converted to trees when adding an element to a
     * bin with at least this many nodes. The value must be greater
     * than 2 and should be at least 8 to mesh with assumptions in
     * tree removal about conversion back to plain bins upon
     * shrinkage.
     */
    enum int TREEIFY_THRESHOLD = 8;

    /**
     * The smallest table capacity for which bins may be treeified.
     * (Otherwise the table is resized if too many nodes in a bin.)
     * Should be at least 4 * TREEIFY_THRESHOLD to avoid conflicts
     * between resizing and treeification thresholds.
     */
    enum int MIN_TREEIFY_CAPACITY = 64;

    /* ---------------- Static utilities -------------- */

    /**
     * Computes key.toHash() and spreads (XORs) higher bits of hash
     * to lower.  Because the table uses power-of-two masking, sets of
     * hashes that vary only in bits above the current mask will
     * always collide. (Among known examples are sets of Float keys
     * holding consecutive whole numbers in small tables.)  So we
     * apply a transform that spreads the impact of higher bits
     * downward. There is a tradeoff between speed, utility, and
     * quality of bit-spreading. Because many common sets of hashes
     * are already reasonably distributed (so don't benefit from
     * spreading), and because we use trees to handle large sets of
     * collisions in bins, we just XOR some shifted bits in the
     * cheapest possible way to reduce systematic lossage, as well as
     * to incorporate impact of the highest bits that would otherwise
     * never be used in index calculations because of table bounds.
     */
    static size_t hash(K key) {
        size_t h;
        static if(is(K == class)) {
            return (key is null) ? 0 : (h = key.toHash()) ^ (h >>> 16);
        }
        else {
            h = hashOf(key);
            return  h ^ (h >>> 16);
        }
    }

    /**
     * Returns x's Class if it is of the form "class C implements
     * Comparable<C>", else null.
     */
    // static Class<?> comparableClassFor(Object x) {
    //     if (x instanceof Comparable) {
    //         Class<?> c; Type[] ts, as; Type t; ParameterizedType p;
    //         if ((c = x.getClass()) == string.class) // bypass checks
    //             return c;
    //         if ((ts = c.getGenericInterfaces()) !is null) {
    //             for (int i = 0; i < ts.length; ++i) {
    //                 if (((t = ts[i]) instanceof ParameterizedType) &&
    //                     ((p = (ParameterizedType)t).getRawType() ==
    //                      Comparable.class) &&
    //                     (as = p.getActualTypeArguments()) !is null &&
    //                     as.length == 1 && as[0] == c) // type arg is c
    //                     return c;
    //             }
    //         }
    //     }
    //     return null;
    // }

    /**
     * Returns k.compareTo(x) if x matches kc (k's screened comparable
     * class), else 0.
     */
    //  // for cast to Comparable
    // static int compareComparables(Class<?> kc, Object k, Object x) {
    //     return (x is null || x.getClass() != kc ? 0 :
    //             ((Comparable)k).compareTo(x));
    // }

    /**
     * Returns a power of two size for the given target capacity.
     */
    static final int tableSizeFor(int cap) {
        int n = cap - 1;
        n |= n >>> 1;
        n |= n >>> 2;
        n |= n >>> 4;
        n |= n >>> 8;
        n |= n >>> 16;
        return (n < 0) ? 1 : (n >= MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : n + 1;
    }

    /* ---------------- Fields -------------- */

    /**
     * The table, initialized on first use, and resized as
     * necessary. When allocated, length is always a power of two.
     * (We also tolerate length zero in some operations to allow
     * bootstrapping mechanics that are currently not needed.)
     */
    HashMapNode!(K,V)[] table;

    /**
     * Holds cached entrySet(). Note that AbstractMap fields are used
     * for keySet() and values().
     */
    // Set<MapEntry!(K,V)> entrySet;

    /**
     * The number of key-value mappings contained in this map.
     */
    // int _size;

    /**
     * The number of times this HashMap has been structurally modified
     * Structural modifications are those that change the number of mappings in
     * the HashMap or otherwise modify its internal structure (e.g.,
     * rehash).  This field is used to make iterators on Collection-views of
     * the HashMap fail-fast.  (See ConcurrentModificationException).
     */
    int modCount;

    /**
     * The next size value at which to resize (capacity * load factor).
     *
     * @serial
     */
    // (The javadoc description is true upon serialization.
    // Additionally, if the table array has not been allocated, this
    // field holds the initial array capacity, or zero signifying
    // DEFAULT_INITIAL_CAPACITY.)
    int threshold;

    /**
     * The load factor for the hash table.
     *
     * @serial
     */
    float loadFactor;

    /* ---------------- Public operations -------------- */

    /**
     * Constructs an empty <tt>HashMap</tt> with the specified initial
     * capacity and load factor.
     *
     * @param  initialCapacity the initial capacity
     * @param  loadFactor      the load factor
     * @throws IllegalArgumentException if the initial capacity is negative
     *         or the load factor is nonpositive
     */
    this(int initialCapacity, float loadFactor) {
        if (initialCapacity < 0)
            throw new IllegalArgumentException("Illegal initial capacity: " ~
                                               initialCapacity.to!string());
        if (initialCapacity > MAXIMUM_CAPACITY)
            initialCapacity = MAXIMUM_CAPACITY;
        if (loadFactor <= 0 || isNaN(loadFactor))
            throw new IllegalArgumentException("Illegal load factor: " ~
                                               loadFactor.to!string());
        this.loadFactor = loadFactor;
        this.threshold = tableSizeFor(initialCapacity);
    }

    /**
     * Constructs an empty <tt>HashMap</tt> with the specified initial
     * capacity and the default load factor (0.75).
     *
     * @param  initialCapacity the initial capacity.
     * @throws IllegalArgumentException if the initial capacity is negative.
     */
    this(int initialCapacity) {
        this(initialCapacity, DEFAULT_LOAD_FACTOR);
    }

    /**
     * Constructs an empty <tt>HashMap</tt> with the default initial capacity
     * (16) and the default load factor (0.75).
     */
    this() {
        this.loadFactor = DEFAULT_LOAD_FACTOR; // all other fields defaulted
    }

    /**
     * Constructs a new <tt>HashMap</tt> with the same mappings as the
     * specified <tt>Map</tt>.  The <tt>HashMap</tt> is created with
     * default load factor (0.75) and an initial capacity sufficient to
     * hold the mappings in the specified <tt>Map</tt>.
     *
     * @param   m the map whose mappings are to be placed in this map
     * @throws  NullPointerException if the specified map is null
     */
    this(Map!(K, V) m) {
        this.loadFactor = DEFAULT_LOAD_FACTOR;
        putMapEntries(m, false);
    }

    /**
     * Implements Map.putAll and Map constructor
     *
     * @param m the map
     * @param evict false when initially constructing this map, else
     * true (relayed to method afterNodeInsertion).
     */
    final void putMapEntries(Map!(K, V) m, bool evict) {
        // throw new NotImplementedException("");
        int s = m.size();
        if (s > 0) {
            if (table is null) { // pre-size
                float ft = (cast(float)s / loadFactor) + 1.0F;
                int t = ((ft < cast(float)MAXIMUM_CAPACITY) ?
                         cast(int)ft : MAXIMUM_CAPACITY);
                if (t > threshold)
                    threshold = tableSizeFor(t);
            }
            else if (s > threshold)
                resize();
            // for (MapEntry!(K, V) e : m.entrySet()) {
            foreach(K key, V value; m) {
                // K key = e.getKey();
                // V value = e.getValue();
                putVal(hash(key), key, value, false, evict);
            }
        }
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
     *
     * @see #put(Object, Object)
     */
    override V get(K key) {
        HashMapNode!(K, V) e = getNode(hash(key), key);
        return e is null ? V.init : e.value;
    }

    /**
     * Implements Map.get and related methods
     *
     * @param hash hash for key
     * @param key the key
     * @return the node, or null if none
     */
    final HashMapNode!(K, V) getNode(size_t hash, K key) {
        HashMapNode!(K, V)[] tab; HashMapNode!(K, V) first, e; size_t n; K k;
        if ((tab = table) !is null && (n = tab.length) > 0 &&
            (first = tab[(n - 1) & hash]) !is null) {
            k = first.key;
            if (first.hash == hash && // always check first node
                k == key )
                return first;
            if ((e = first.next) !is null) {
                auto tempNode = cast(TreeNode!(K, V))first;
                if (tempNode !is null)
                    return tempNode.getTreeNode(hash, key);
                do {
                    k = e.key;
                    if (e.hash == hash && k == key)
                        return e;
                } while ((e = e.next) !is null);
            }
        }
        return null;
    }

    /**
     * Returns <tt>true</tt> if this map contains a mapping for the
     * specified key.
     *
     * @param   key   The key whose presence in this map is to be tested
     * @return <tt>true</tt> if this map contains a mapping for the specified
     * key.
     */
    override bool containsKey(K key) {
        return getNode(hash(key), key) !is null;
    }

    /**
     * Associates the specified value with the specified key in this map.
     * If the map previously contained a mapping for the key, the old
     * value is replaced.
     *
     * @param key key with which the specified value is to be associated
     * @param value value to be associated with the specified key
     * @return the previous value associated with <tt>key</tt>, or
     *         <tt>null</tt> if there was no mapping for <tt>key</tt>.
     *         (A <tt>null</tt> return can also indicate that the map
     *         previously associated <tt>null</tt> with <tt>key</tt>.)
     */
    override V put(K key, V value) {
        return putVal(hash(key), key, value, false, true);
    }

    /**
     * Implements Map.put and related methods
     *
     * @param hash hash for key
     * @param key the key
     * @param value the value to put
     * @param onlyIfAbsent if true, don't change existing value
     * @param evict if false, the table is in creation mode.
     * @return previous value, or null if none
     */
    final V putVal(size_t hash, K key, V value, bool onlyIfAbsent, bool evict) {
        HashMapNode!(K, V)[] tab; HashMapNode!(K, V) p; 
        size_t n;
        if ((tab = table) is null || (n = tab.length) == 0)
            n = (tab = resize()).length;

        size_t i = (n - 1) & hash;
        if ((p = tab[i]) is null) {
            tab[i] = newNode(hash, key, value, null);
        }
        else {
            HashMapNode!(K, V) e; K k;
            k = p.key;
            if (p.hash == hash && k == key)
                e = p;
            else{
                TreeNode!(K, V) pp = cast(TreeNode!(K, V))p;
                if (pp !is null)
                    e = pp.putTreeVal(this, tab, hash, key, value);
                else {
                    for (int binCount = 0; ; ++binCount) {
                        if ((e = p.next) is null) {
                            p.next = newNode(hash, key, value, null);
                            if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                                treeifyBin(tab, hash);
                            break;
                        }
                        k = e.key;
                        if (e.hash == hash && k == key )
                            break;
                        p = e;
                    }
                }
            }

            if (e !is null) { // existing mapping for key
                V oldValue = e.value;
                static if( is(V == class)) {
                    if (!onlyIfAbsent || oldValue is null)
                        e.value = value;
                }
                else {
                    if (!onlyIfAbsent)
                        e.value = value;
                }
                afterNodeAccess(e);
                return oldValue;
            }
        }
        ++modCount;
        if (++_size > threshold)
            resize();
        afterNodeInsertion(evict);
        return V.init;                       
    }

  
    /**
     * Initializes or doubles table size.  If null, allocates in
     * accord with initial capacity target held in field threshold.
     * Otherwise, because we are using power-of-two expansion, the
     * elements from each bin must either stay at same index, or move
     * with a power of two offset in the new table.
     *
     * @return the table
     */
    final HashMapNode!(K,V)[] resize() {
        HashMapNode!(K,V)[] oldTab = table;
        int oldCap = (oldTab is null) ? 0 : cast(int)oldTab.length;
        int oldThr = threshold;
        int newCap, newThr = 0;
        if (oldCap > 0) {
            if (oldCap >= MAXIMUM_CAPACITY) {
                threshold = int.max;
                return oldTab;
            }
            else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
                     oldCap >= DEFAULT_INITIAL_CAPACITY)
                newThr = oldThr << 1; // double threshold
        }
        else if (oldThr > 0) // initial capacity was placed in threshold
            newCap = oldThr;
        else {               // zero initial threshold signifies using defaults
            newCap = DEFAULT_INITIAL_CAPACITY;
            newThr = cast(int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
        }
        if (newThr == 0) {
            float ft = cast(float)newCap * loadFactor;
            newThr = (newCap < MAXIMUM_CAPACITY && ft < cast(float)MAXIMUM_CAPACITY ?
                      cast(int)ft : int.max);
        }
        threshold = newThr;

        HashMapNode!(K,V)[] newTab = new HashMapNode!(K,V)[newCap];
        TreeNode!(K,V) ee;
        table = newTab;
        if (oldTab !is null) {
            for (int j = 0; j < oldCap; ++j) {
                HashMapNode!(K,V) e;
                if ((e = oldTab[j]) !is null) {
                    oldTab[j] = null;
                    if (e.next is null)
                        newTab[e.hash & (newCap - 1)] = e;
                    else if ((ee = cast(TreeNode!(K,V))e) !is null)
                        ee.split(this, newTab, j, oldCap);
                    else { // preserve order
                        HashMapNode!(K,V) loHead = null, loTail = null;
                        HashMapNode!(K,V) hiHead = null, hiTail = null;
                        HashMapNode!(K,V) next;
                        do {
                            next = e.next;
                            if ((e.hash & oldCap) == 0) {
                                if (loTail is null)
                                    loHead = e;
                                else
                                    loTail.next = e;
                                loTail = e;
                            }
                            else {
                                if (hiTail is null)
                                    hiHead = e;
                                else
                                    hiTail.next = e;
                                hiTail = e;
                            }
                        } while ((e = next) !is null);
                        if (loTail !is null) {
                            loTail.next = null;
                            newTab[j] = loHead;
                        }
                        if (hiTail !is null) {
                            hiTail.next = null;
                            newTab[j + oldCap] = hiHead;
                        }
                    }
                }
            }
        }
        return newTab;
    }

    /**
     * Replaces all linked nodes in bin at index for given hash unless
     * table is too small, in which case resizes instead.
     */
    final void treeifyBin(HashMapNode!(K,V)[] tab, size_t hash) {
        size_t n, index; HashMapNode!(K,V) e;
        if (tab is null || (n = tab.length) < MIN_TREEIFY_CAPACITY)
            resize();
        else if ((e = tab[index = (n - 1) & hash]) !is null) {
            TreeNode!(K,V) hd = null, tl = null;
            do {
                TreeNode!(K,V) p = replacementTreeNode(e, null);
                if (tl is null)
                    hd = p;
                else {
                    p.prev = tl;
                    tl.next = p;
                }
                tl = p;
            } while ((e = e.next) !is null);
            if ((tab[index] = hd) !is null)
                hd.treeify(tab);
        }
    }

    /**
     * Copies all of the mappings from the specified map to this map.
     * These mappings will replace any mappings that this map had for
     * any of the keys currently in the specified map.
     *
     * @param m mappings to be stored in this map
     * @throws NullPointerException if the specified map is null
     */
    // override void putAll(Map!(K, V) m) {
    //     putMapEntries(m, true);
    // }

    /**
     * Removes the mapping for the specified key from this map if present.
     *
     * @param  key key whose mapping is to be removed from the map
     * @return the previous value associated with <tt>key</tt>, or
     *         <tt>null</tt> if there was no mapping for <tt>key</tt>.
     *         (A <tt>null</tt> return can also indicate that the map
     *         previously associated <tt>null</tt> with <tt>key</tt>.)
     */
    override V remove(K key) {
        HashMapNode!(K,V) e = removeNode(hash(key), key, V.init, false, true);
        return e is null ? V.init : e.value;
    }

    alias remove = AbstractMap!(K, V).remove;

    /**
     * Implements Map.remove and related methods
     *
     * @param hash hash for key
     * @param key the key
     * @param value the value to match if matchValue, else ignored
     * @param matchValue if true only remove if value is equal
     * @param movable if false do not move other nodes while removing
     * @return the node, or null if none
     */
    final HashMapNode!(K,V) removeNode(size_t hash, K key, V value,
                               bool matchValue, bool movable) {
        HashMapNode!(K,V)[] tab; HashMapNode!(K,V) p; 
        size_t n, index;
        if ((tab = table) !is null && (n = tab.length) > 0 &&
            (p = tab[index = (n - 1) & hash]) !is null) {
            HashMapNode!(K,V) node = null, e; K k; V v;
            k = p.key;
            if (p.hash == hash && k == key )
                node = p;
            else if ((e = p.next) !is null) {
                TreeNode!(K,V) pp = cast(TreeNode!(K,V))p;
                if (pp !is null)
                    node = pp.getTreeNode(hash, key);
                else {
                    do {
                        k = e.key;
                        if (e.hash == hash && k == key ) {
                            node = e;
                            break;
                        }
                        p = e;
                    } while ((e = e.next) !is null);
                }
            }
            if (node !is null && (!matchValue || (v = node.value) == value)) {
                auto _node = cast(TreeNode!(K,V))node;
                if (_node !is null)
                    _node.removeTreeNode(this, tab, movable);
                else if (node == p)
                    tab[index] = node.next;
                else
                    p.next = node.next;
                ++modCount;
                --_size;
                afterNodeRemoval(node);
                return node;
            }
        }
        return null;
    }

    /**
     * Removes all of the mappings from this map.
     * The map will be empty after this call returns.
     */
    override void clear() {
        HashMapNode!(K,V)[] tab;
        modCount++;
        if ((tab = table) !is null && size > 0) {
            _size = 0;
            for (size_t i = 0; i < tab.length; ++i)
                tab[i] = null;
        }
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
        HashMapNode!(K, V)[] tab; V v;
        if ((tab = table) !is null && size > 0) {
            for (size_t i = 0; i < tab.length; ++i) {
                for (HashMapNode!(K, V) e = tab[i]; e !is null; e = e.next) {
                    v = e.value;
                    // if ((v = e.value) == value ||
                    //     (value !is null && value == v))
                    if(v == value)
                        return true;
                }
            }
        }
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
     *
     * @return a set view of the keys contained in this map
     */
    // Set!K keySet() {
    //     Set!K ks = keySet;
    //     if (ks is null) {
    //         ks = new KeySet();
    //         keySet = ks;
    //     }
    //     return ks;
    // }

    /* ------------------------------------------------------------ */
    // iterators

    override int opApply(scope int delegate(ref K, ref V) dg) {
        if(dg is null)
            throw new NullPointerException();
        HashMapNode!(K, V)[] tab = table;

        int result = 0;
        if(_size > 0 && tab !is null) {
            int mc = modCount;
            for(size_t i=0; i<tab.length; i++) {
                for(HashMapNode!(K, V) e = tab[i]; e !is null; e = e.next) {
                    result = dg(e.key, e.value);
                    if(result != 0) return result;
                }
            }

            if(modCount != mc)
                throw new ConcurrentModificationException();
        }

        return result;
    }

    override int opApply(scope int delegate(MapEntry!(K, V) entry) dg) {
        if(dg is null)
            throw new NullPointerException("");
        HashMapNode!(K, V)[] tab = table;

        if(_size <= 0 || tab is null) 
            return 0;
        
        int result = 0;
        int mc = modCount;
        for(size_t i=0; i<tab.length; i++) {
            for(HashMapNode!(K, V) e = tab[i]; e !is null; e = e.next) {
                result = dg(e);
                if(result != 0) return result;
            }
        }

        if(modCount != mc)
            throw new ConcurrentModificationException("");

        return result;
    }

    override InputRange!K byKey() {
        return new KeyInputRange();
    }

    override InputRange!V byValue() {
        return new ValueInputRange();
    }
    
    
    mixin template HashIterator() {
        protected HashMapNode!(K, V) next;        // next entry to return
        protected HashMapNode!(K, V) current;     // current entry
        protected int expectedModCount;  // for fast-fail
        protected int index;             // current slot

        this() {
            expectedModCount = modCount;
            HashMapNode!(K, V)[] t = table;
            next = null;
            index = 0;
            if (t !is null && size > 0) { // advance to first entry
                do {} while (index < t.length && (next = t[index++]) is null);
            }
            current = next;
        }

        final bool empty() {
            return next is null;
        }

        void popFront() {
            HashMapNode!(K, V)[] t;
            HashMapNode!(K, V) e = next;
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
            if (e is null)
                throw new NoSuchElementException();
            if ((next = (current = e).next) is null && (t = table) !is null) {
                do {} while (index < t.length && (next = t[index++]) is null);
            }
        }
    }

    final class KeyInputRange :  InputRange!K {
        mixin HashIterator;

        final K front() @property { return next.key; }

        // https://forum.dlang.org/thread/amzthhonuozlobghqqgk@forum.dlang.org?page=1
        // https://issues.dlang.org/show_bug.cgi?id=18036
        final K moveFront() @property { throw new NotSupportedException(); }
        
        int opApply(scope int delegate(K) dg) {
            if(dg is null)
                throw new NullPointerException("");

            if(_size <= 0 || table is null) 
                return 0;
            
            HashMapNode!(K, V)[] tab = table;
            int result = 0;
            int mc = modCount;
            for(size_t i=0; i<tab.length; i++) {
                for(HashMapNode!(K, V) e = tab[i]; e !is null; e = e.next) {
                    result = dg(e.key);
                    if(result != 0) return result;
                }
            }

            if(modCount != mc)
                throw new ConcurrentModificationException("");

            return result;
        }

        int opApply(scope int delegate(size_t, K) dg) {
            if(dg is null)
                throw new NullPointerException("");
                
            if(_size <= 0 || table is null) 
                return 0;
            
            HashMapNode!(K, V)[] tab = table;
            int result = 0;
            int mc = modCount;            
            size_t index = 0;

            for(size_t i=0; i<tab.length; i++) {
                for(HashMapNode!(K, V) e = tab[i]; e !is null; e = e.next) {
                    result = dg(index++, e.key);
                    if(result != 0) return result;
                }
            }

            if(modCount != mc)
                throw new ConcurrentModificationException("");

            return result;
        }
    }
    
    final class ValueInputRange :  InputRange!V {
        mixin HashIterator;

        final V front() @property { return next.value; }

        final V moveFront() @property { throw new NotSupportedException(); }
        
        int opApply(scope int delegate(V) dg)
        {
            if(dg is null)
                throw new NullPointerException("");

            if(_size <= 0 || table is null) 
                return 0;
            
            HashMapNode!(K, V)[] tab = table;
            int result = 0;
            int mc = modCount;
            for(size_t i=0; i<tab.length; i++)
            {
                for(HashMapNode!(K, V) e = tab[i]; e !is null; e = e.next)
                {
                    result = dg(e.value);
                    if(result != 0) return result;
                }
            }

            if(modCount != mc)
                throw new ConcurrentModificationException("");

            return result;
        }

        int opApply(scope int delegate(size_t, V) dg) {
            if(dg is null)
                throw new NullPointerException("");
                
            if(_size <= 0 || table is null) 
                return 0;
            
            HashMapNode!(K, V)[] tab = table;
            int result = 0;
            int mc = modCount;
            size_t index = 0;
            for(size_t i=0; i<tab.length; i++) {
                for(HashMapNode!(K, V) e = tab[i]; e !is null; e = e.next)
                {
                    result = dg(index++, e.value);
                    if(result != 0) return result;
                }
            }

            if(modCount != mc)
                throw new ConcurrentModificationException("");

            return result;
        }
    }



    // for Test
    // Iterator!K keyIterator()
    // {
    //     return new KeyIterator();
    // }
    
    // mixin template HashIterator() {
    //     HashMapNode!(K, V) _next;        // next entry to return
    //     HashMapNode!(K, V) current;     // current entry
    //     int expectedModCount;  // for fast-fail
    //     int index;             // current slot

    //     this() {
    //         expectedModCount = modCount;
    //         HashMapNode!(K, V)[] t = table;
    //         current = _next = null;
    //         index = 0;
    //         if (t !is null && size > 0) { // advance to first entry
    //             do {} while (index < t.length && (_next = t[index++]) is null);
    //         }
    //     }

    //     void next(HashMapNode!(K, V) v) { _next = v; }

    //     final bool hasNext() {
    //         return _next !is null;
    //     }

    //     final HashMapNode!(K, V) nextNode() {
    //         HashMapNode!(K, V)[] t;
    //         HashMapNode!(K, V) e = _next;
    //         if (modCount != expectedModCount)
    //             throw new ConcurrentModificationException();
    //         if (e is null)
    //             throw new NoSuchElementException();
    //         if ((_next = (current = e).next) is null && (t = table) !is null) {
    //             do {} while (index < t.length && (_next = t[index++]) is null);
    //         }
    //         return e;
    //     }

    //     final void remove() {
    //         HashMapNode!(K, V) p = current;
    //         if (p is null)
    //             throw new IllegalStateException();
    //         if (modCount != expectedModCount)
    //             throw new ConcurrentModificationException();
    //         current = null;
    //         K key = p.key;
    //         removeNode(hash(key), key, null, false, false);
    //         expectedModCount = modCount;
    //     }
    // }

    // final class KeyIterator :  Iterator!K {
    //     mixin HashIterator;
    //     final K next() { return nextNode().key; }
    // }

    // final class ValueIterator : HashIterator
    //     implements Iterator!V {
    //     final V next() { return nextNode().value; }
    // }

    // final class EntryIterator : HashIterator
    //     implements Iterator<MapEntry!(K,V)> {
    //     final MapEntry!(K,V) next() { return nextNode(); }
    // }

    // Overrides of JDK8 Map extension methods

    // override
    // V getOrDefault(Object key, V defaultValue) {
    //     HashMapNode!(K,V) e;
    //     return (e = getNode(hash(key), key)) is null ? defaultValue : e.value;
    // }

    // override
    // V putIfAbsent(K key, V value) {
    //     return putVal(hash(key), key, value, true, true);
    // }

    // override
    // bool remove(Object key, Object value) {
    //     return removeNode(hash(key), key, value, true, true) !is null;
    // }

    // override
    // bool replace(K key, V oldValue, V newValue) {
    //     HashMapNode!(K,V) e; V v;
    //     if ((e = getNode(hash(key), key)) !is null &&
    //         ((v = e.value) == oldValue || (v !is null && v.equals(oldValue)))) {
    //         e.value = newValue;
    //         afterNodeAccess(e);
    //         return true;
    //     }
    //     return false;
    // }

    // override
    // V replace(K key, V value) {
    //     HashMapNode!(K,V) e;
    //     if ((e = getNode(hash(key), key)) !is null) {
    //         V oldValue = e.value;
    //         e.value = value;
    //         afterNodeAccess(e);
    //         return oldValue;
    //     }
    //     return null;
    // }

    // override
    // V computeIfAbsent(K key,
    //                          Function<K, V> mappingFunction) {
    //     if (mappingFunction is null)
    //         throw new NullPointerException();
    //     int hash = hash(key);
    //     HashMapNode!(K,V)[] tab; HashMapNode!(K,V) first; int n, i;
    //     int binCount = 0;
    //     TreeNode!(K,V) t = null;
    //     HashMapNode!(K,V) old = null;
    //     if (size > threshold || (tab = table) is null ||
    //         (n = tab.length) == 0)
    //         n = (tab = resize()).length;
    //     if ((first = tab[i = (n - 1) & hash]) !is null) {
    //         if (first instanceof TreeNode)
    //             old = (t = (TreeNode!(K,V))first).getTreeNode(hash, key);
    //         else {
    //             HashMapNode!(K,V) e = first; K k;
    //             do {
    //                 if (e.hash == hash &&
    //                     ((k = e.key) == key || (key !is null && key.equals(k)))) {
    //                     old = e;
    //                     break;
    //                 }
    //                 ++binCount;
    //             } while ((e = e.next) !is null);
    //         }
    //         V oldValue;
    //         if (old !is null && (oldValue = old.value) !is null) {
    //             afterNodeAccess(old);
    //             return oldValue;
    //         }
    //     }
    //     V v = mappingFunction.apply(key);
    //     if (v is null) {
    //         return null;
    //     } else if (old !is null) {
    //         old.value = v;
    //         afterNodeAccess(old);
    //         return v;
    //     }
    //     else if (t !is null)
    //         t.putTreeVal(this, tab, hash, key, v);
    //     else {
    //         tab[i] = newNode(hash, key, v, first);
    //         if (binCount >= TREEIFY_THRESHOLD - 1)
    //             treeifyBin(tab, hash);
    //     }
    //     ++modCount;
    //     ++size;
    //     afterNodeInsertion(true);
    //     return v;
    // }

    // V computeIfPresent(K key,
    //                           BiFunction<K, V, V> remappingFunction) {
    //     if (remappingFunction is null)
    //         throw new NullPointerException();
    //     HashMapNode!(K,V) e; V oldValue;
    //     int hash = hash(key);
    //     if ((e = getNode(hash, key)) !is null &&
    //         (oldValue = e.value) !is null) {
    //         V v = remappingFunction.apply(key, oldValue);
    //         if (v !is null) {
    //             e.value = v;
    //             afterNodeAccess(e);
    //             return v;
    //         }
    //         else
    //             removeNode(hash, key, null, false, true);
    //     }
    //     return null;
    // }

    // override
    // V compute(K key,
    //                  BiFunction<K, V, V> remappingFunction) {
    //     if (remappingFunction is null)
    //         throw new NullPointerException();
    //     int hash = hash(key);
    //     HashMapNode!(K,V)[] tab; HashMapNode!(K,V) first; int n, i;
    //     int binCount = 0;
    //     TreeNode!(K,V) t = null;
    //     HashMapNode!(K,V) old = null;
    //     if (size > threshold || (tab = table) is null ||
    //         (n = tab.length) == 0)
    //         n = (tab = resize()).length;
    //     if ((first = tab[i = (n - 1) & hash]) !is null) {
    //         if (first instanceof TreeNode)
    //             old = (t = (TreeNode!(K,V))first).getTreeNode(hash, key);
    //         else {
    //             HashMapNode!(K,V) e = first; K k;
    //             do {
    //                 if (e.hash == hash &&
    //                     ((k = e.key) == key || (key !is null && key.equals(k)))) {
    //                     old = e;
    //                     break;
    //                 }
    //                 ++binCount;
    //             } while ((e = e.next) !is null);
    //         }
    //     }
    //     V oldValue = (old is null) ? null : old.value;
    //     V v = remappingFunction.apply(key, oldValue);
    //     if (old !is null) {
    //         if (v !is null) {
    //             old.value = v;
    //             afterNodeAccess(old);
    //         }
    //         else
    //             removeNode(hash, key, null, false, true);
    //     }
    //     else if (v !is null) {
    //         if (t !is null)
    //             t.putTreeVal(this, tab, hash, key, v);
    //         else {
    //             tab[i] = newNode(hash, key, v, first);
    //             if (binCount >= TREEIFY_THRESHOLD - 1)
    //                 treeifyBin(tab, hash);
    //         }
    //         ++modCount;
    //         ++size;
    //         afterNodeInsertion(true);
    //     }
    //     return v;
    // }

    // override
    // V merge(K key, V value,
    //                BiFunction<V, V, V> remappingFunction) {
    //     if (value is null)
    //         throw new NullPointerException();
    //     if (remappingFunction is null)
    //         throw new NullPointerException();
    //     int hash = hash(key);
    //     HashMapNode!(K,V)[] tab; HashMapNode!(K,V) first; int n, i;
    //     int binCount = 0;
    //     TreeNode!(K,V) t = null;
    //     HashMapNode!(K,V) old = null;
    //     if (size > threshold || (tab = table) is null ||
    //         (n = tab.length) == 0)
    //         n = (tab = resize()).length;
    //     if ((first = tab[i = (n - 1) & hash]) !is null) {
    //         if (first instanceof TreeNode)
    //             old = (t = (TreeNode!(K,V))first).getTreeNode(hash, key);
    //         else {
    //             HashMapNode!(K,V) e = first; K k;
    //             do {
    //                 if (e.hash == hash &&
    //                     ((k = e.key) == key || (key !is null && key.equals(k)))) {
    //                     old = e;
    //                     break;
    //                 }
    //                 ++binCount;
    //             } while ((e = e.next) !is null);
    //         }
    //     }
    //     if (old !is null) {
    //         V v;
    //         if (old.value !is null)
    //             v = remappingFunction.apply(old.value, value);
    //         else
    //             v = value;
    //         if (v !is null) {
    //             old.value = v;
    //             afterNodeAccess(old);
    //         }
    //         else
    //             removeNode(hash, key, null, false, true);
    //         return v;
    //     }
    //     if (value !is null) {
    //         if (t !is null)
    //             t.putTreeVal(this, tab, hash, key, value);
    //         else {
    //             tab[i] = newNode(hash, key, value, first);
    //             if (binCount >= TREEIFY_THRESHOLD - 1)
    //                 treeifyBin(tab, hash);
    //         }
    //         ++modCount;
    //         ++size;
    //         afterNodeInsertion(true);
    //     }
    //     return value;
    // }


    /* ------------------------------------------------------------ */
    // LinkedHashMap support

    /*
     * The following package-protected methods are designed to be
     * overridden by LinkedHashMap, but not by any other subclass.
     * Nearly all other internal methods are also package-protected
     * but are declared final, so can be used by LinkedHashMap, view
     * classes, and HashSet.
     */

    // Create a regular (non-tree) node
    HashMapNode!(K,V) newNode(size_t hash, K key, V value, HashMapNode!(K,V) next) {
        return new HashMapNode!(K,V)(hash, key, value, next);
    }

    // For conversion from TreeNodes to plain nodes
    HashMapNode!(K,V) replacementNode(HashMapNode!(K,V) p, HashMapNode!(K,V) next) {
        return new HashMapNode!(K,V)(p.hash, p.key, p.value, next);
    }

    // Create a tree bin node
    TreeNode!(K,V) newTreeNode(size_t hash, K key, V value, HashMapNode!(K,V) next) {
        return new TreeNode!(K,V)(hash, key, value, next);
    }

    // For treeifyBin
    TreeNode!(K,V) replacementTreeNode(HashMapNode!(K,V) p, HashMapNode!(K,V) next) {
        return new TreeNode!(K,V)(p.hash, p.key, p.value, next);
    }

    /**
     * Reset to initial default state.  Called by clone and readObject.
     */
    void reinitialize() {
        table = null;
        // entrySet = null;
        // _keySet = null;
        // _values = null;
        modCount = 0;
        threshold = 0;
        _size = 0;
    }

    // Callbacks to allow LinkedHashMap post-actions
    void afterNodeAccess(HashMapNode!(K,V) p) { }
    void afterNodeInsertion(bool evict) { }
    void afterNodeRemoval(HashMapNode!(K,V) p) { }

    // Called only from writeObject, to ensure compatible ordering.
    // void internalWriteEntries(java.io.ObjectOutputStream s) {
    //     HashMapNode!(K,V)[] tab;
    //     if (size > 0 && (tab = table) !is null) {
    //         for (int i = 0; i < tab.length; ++i) {
    //             for (HashMapNode!(K,V) e = tab[i]; e !is null; e = e.next) {
    //                 s.writeObject(e.key);
    //                 s.writeObject(e.value);
    //             }
    //         }
    //     }
    // }
  
}

/* ------------------------------------------------------------ */
// Tree bins

/**
 * Entry for Tree bins. Extends LinkedHashMap.Entry (which in turn
 * extends Node) so can be used as extension of either regular or
 * linked node.
 */
final class TreeNode(K, V) : LinkedHashMapEntry!(K, V) {

    /**
     * The bin count threshold for untreeifying a (split) bin during a
     * resize operation. Should be less than TREEIFY_THRESHOLD, and at
     * most 6 to mesh with shrinkage detection under removal.
     */
    enum int UNTREEIFY_THRESHOLD = 6;

    TreeNode!(K, V) parent;  // red-black tree links
    TreeNode!(K, V) left;
    TreeNode!(K, V) right;
    TreeNode!(K, V) prev;    // needed to unlink next upon deletion
    bool red;

    this(size_t hash, K key, V val, HashMapNode!(K, V) next) {
        super(hash, key, val, next);
    }

    /**
     * Returns root of tree containing this node.
     */
    final TreeNode!(K, V) root() {
        for (TreeNode!(K, V) r = this, p;;) {
            if ((p = r.parent) is null)
                return r;
            r = p;
        }
    }

    /**
     * Ensures that the given root is the first node of its bin.
     */
    static void moveRootToFront(K, V)(HashMapNode!(K, V)[] tab, TreeNode!(K, V) root) {
        size_t n;
        if (root !is null && tab !is null && (n = tab.length) > 0) {
            size_t index = (n - 1) & root.hash;
            TreeNode!(K, V) first = cast(TreeNode!(K, V))tab[index];
            if (root != first) {
                HashMapNode!(K, V) rn;
                tab[index] = root;
                TreeNode!(K, V) rp = root.prev;
                if ((rn = root.next) !is null)
                    (cast(TreeNode!(K, V))rn).prev = rp;
                if (rp !is null)
                    rp.next = rn;
                if (first !is null)
                    first.prev = root;
                root.next = first;
                root.prev = null;
            }
            assert(checkInvariants(root));
        }
    }

    /**
     * Finds the node starting at root p with the given hash and key.
     * The kc argument caches comparableClassFor(key) upon first use
     * comparing keys.
     */
    final TreeNode!(K, V) find(size_t h, K k) {
        TreeNode!(K, V) p = this;
        do {
            size_t ph; int dir; K pk;
            TreeNode!(K, V) pl = p.left, pr = p.right, q;
            if ((ph = p.hash) > h)
                p = pl;
            else if (ph < h)
                p = pr;
            else {
                pk = p.key;
                if (pk == k)
                    return p;
                else if (pl is null)
                    p = pr;
                else if (pr is null)
                    p = pl;
                else {
                    // static if(isNumeric!(K)) { dir = std.math.cmp(cast(float)k, cast(float)pk); }
                    // else { dir = std.algorithm.cmp(k, pk); }    

                    // if (dir != 0)
                    //     p = (dir < 0) ? pl : pr;
                    // else if ((q = pr.find(h, k)) !is null)
                    //     return q;
                    // else
                    //     p = pl;
                    if(k < pk) 
                        p = pl;
                    else if( k>pk) 
                        p = pr;
                    else if ((q = pr.find(h, k)) !is null)
                        return q;
                    else
                        p = pl; 
                }
            } 
        } while (p !is null);
        return null;
    }

    /**
     * Calls find for root node.
     */
    final TreeNode!(K, V) getTreeNode(size_t h, K k) {
        return ((parent !is null) ? root() : this).find(h, k);
    }

    /**
     * Tie-breaking utility for ordering insertions when equal
     * hashCodes and non-comparable. We don't require a total
     * order, just a consistent insertion rule to maintain
     * equivalence across rebalancings. Tie-breaking further than
     * necessary simplifies testing a bit.
     */
    static int tieBreakOrder(T)(T a, T b) if(isBasicType!(T) || isSomeString!T) {
        return (hashOf(a) <= hashOf(b) ? -1 : 1);
    }

    static int tieBreakOrder(T)(T a, T b) if(is(T == class) || is(T == interface)) {
        int d = 0;
        if (a is null || b is null  ||
            (d = std.algorithm.cmp(typeid(a).name, 
                typeid(b).name)) == 0)
            d = ((cast(Object)a).toHash() <= (cast(Object)b).toHash() ? -1 : 1);
        return d;
    }

    static int tieBreakOrder(T)(T a, T b) if(is(T == struct)) {
        int d = std.algorithm.cmp(typeid(a).name,
                typeid(b).name);
        if (d == 0)
            d = (a.toHash() <= b.toHash() ? -1 : 1);
        return d;
    }

    /**
     * Forms tree of the nodes linked from this node.
     * @return root of tree
     */
    final void treeify(HashMapNode!(K, V)[] tab) {
        TreeNode!(K, V) root = null;
        for (TreeNode!(K, V) x = this, next; x !is null; x = next) {
            next = cast(TreeNode!(K, V))x.next;
            x.left = x.right = null;
            if (root is null) {
                x.parent = null;
                x.red = false;
                root = x;
            }
            else {
                K k = x.key;
                size_t h = x.hash;
                for (TreeNode!(K, V) p = root;;) {
                    size_t dir, ph;
                    K pk = p.key;
                    if ((ph = p.hash) > h)
                        dir = -1;
                    else if (ph < h)
                        dir = 1;
                    else {
                        // static if(isNumeric!(K)) { dir = std.math.cmp(cast(float)k, cast(float)pk); }
                        // else { dir = std.algorithm.cmp(k, pk); }
                        if (k == pk)
                            dir = tieBreakOrder!(K)(k, pk);
                        else if(k > pk)
                            dir = 1;
                        else 
                            dir = -1;
                    }

                    TreeNode!(K, V) xp = p;
                    if ((p = (dir <= 0) ? p.left : p.right) is null) {
                        x.parent = xp;
                        if (dir <= 0)
                            xp.left = x;
                        else
                            xp.right = x;
                        root = balanceInsertion(root, x);
                        break;
                    }
                }
            }
        }
        moveRootToFront(tab, root);
    }

    /**
     * Returns a list of non-TreeNodes replacing those linked from
     * this node.
     */
    final HashMapNode!(K, V) untreeify(HashMap!(K, V) map) {
        HashMapNode!(K, V) hd = null, tl = null;
        for (HashMapNode!(K, V) q = this; q !is null; q = q.next) {
            HashMapNode!(K, V) p = map.replacementNode(q, null);
            if (tl is null)
                hd = p;
            else
                tl.next = p;
            tl = p;
        }
        return hd;
    }

    /**
     * Tree version of putVal.
     */
    final TreeNode!(K, V) putTreeVal(HashMap!(K, V) map, HashMapNode!(K, V)[] tab,
                                   size_t h, K k, V v) {
        // Class<?> kc = null;
        bool searched = false;
        TreeNode!(K, V) root = (parent !is null) ? root() : this;
        for (TreeNode!(K, V) p = root;;) {
            size_t ph; K pk; int dir;

            if ((ph = p.hash) > h)
                dir = -1;
            else if (ph < h)
                dir = 1;
            else {
                pk = p.key;
                if (pk == k)
                    return p;
                else {
                    // static if(isNumeric!(K)) { dir = std.math.cmp(cast(float)k, cast(float)pk); }
                    // else { dir = std.algorithm.cmp(k, pk); }

                    if(k == pk) {
                        if (!searched) {
                            TreeNode!(K, V) q, ch;
                            searched = true;
                            if (((ch = p.left) !is null &&
                                (q = ch.find(h, k)) !is null) ||
                                ((ch = p.right) !is null &&
                                (q = ch.find(h, k)) !is null))
                                return q;
                        }
                        dir = tieBreakOrder!(K)(k, pk);
                    } else if(k > pk)
                        dir = 1;
                    else
                        dir = -1;
                }
            }

            TreeNode!(K, V) xp = p;
            if ((p = (dir <= 0) ? p.left : p.right) is null) {
                HashMapNode!(K, V) xpn = xp.next;
                TreeNode!(K, V) x = map.newTreeNode(h, k, v, xpn);
                if (dir <= 0)
                    xp.left = x;
                else
                    xp.right = x;
                xp.next = x;
                x.parent = x.prev = xp;
                if (xpn !is null)
                    (cast(TreeNode!(K, V))xpn).prev = x;
                moveRootToFront(tab, balanceInsertion(root, x));
                return null;
            }
        }
    }

    /**
     * Removes the given node, that must be present before this call.
     * This is messier than typical red-black deletion code because we
     * cannot swap the contents of an interior node with a leaf
     * successor that is pinned by "next" pointers that are accessible
     * independently during traversal. So instead we swap the tree
     * linkages. If the current tree appears to have too few nodes,
     * the bin is converted back to a plain bin. (The test triggers
     * somewhere between 2 and 6 nodes, depending on tree structure).
     */
    final void removeTreeNode(HashMap!(K, V) map, HashMapNode!(K, V)[] tab,
                              bool movable) {
        size_t n;
        if (tab is null || (n = tab.length) == 0)
            return;
        size_t index = (n - 1) & hash;
        TreeNode!(K, V) first = cast(TreeNode!(K, V))tab[index], root = first, rl;
        TreeNode!(K, V) succ = cast(TreeNode!(K, V))next, pred = prev;
        if (pred is null)
            tab[index] = first = succ;
        else
            pred.next = succ;
        if (succ !is null)
            succ.prev = pred;
        if (first is null)
            return;
        if (root.parent !is null)
            root = root.root();
        if (root is null || root.right is null ||
            (rl = root.left) is null || rl.left is null) {
            tab[index] = first.untreeify(map);  // too small
            return;
        }
        TreeNode!(K, V) p = this, pl = left, pr = right, replacement;
        if (pl !is null && pr !is null) {
            TreeNode!(K, V) s = pr, sl;
            while ((sl = s.left) !is null) // find successor
                s = sl;
            bool c = s.red; s.red = p.red; p.red = c; // swap colors
            TreeNode!(K, V) sr = s.right;
            TreeNode!(K, V) pp = p.parent;
            if (s == pr) { // p was s's direct parent
                p.parent = s;
                s.right = p;
            }
            else {
                TreeNode!(K, V) sp = s.parent;
                if ((p.parent = sp) !is null) {
                    if (s == sp.left)
                        sp.left = p;
                    else
                        sp.right = p;
                }
                if ((s.right = pr) !is null)
                    pr.parent = s;
            }
            p.left = null;
            if ((p.right = sr) !is null)
                sr.parent = p;
            if ((s.left = pl) !is null)
                pl.parent = s;
            if ((s.parent = pp) is null)
                root = s;
            else if (p == pp.left)
                pp.left = s;
            else
                pp.right = s;
            if (sr !is null)
                replacement = sr;
            else
                replacement = p;
        }
        else if (pl !is null)
            replacement = pl;
        else if (pr !is null)
            replacement = pr;
        else
            replacement = p;
        if (replacement != p) {
            TreeNode!(K, V) pp = replacement.parent = p.parent;
            if (pp is null)
                root = replacement;
            else if (p == pp.left)
                pp.left = replacement;
            else
                pp.right = replacement;
            p.left = p.right = p.parent = null;
        }

        TreeNode!(K, V) r = p.red ? root : balanceDeletion(root, replacement);

        if (replacement == p) {  // detach
            TreeNode!(K, V) pp = p.parent;
            p.parent = null;
            if (pp !is null) {
                if (p == pp.left)
                    pp.left = null;
                else if (p == pp.right)
                    pp.right = null;
            }
        }
        if (movable)
            moveRootToFront(tab, r);
    }

    /**
     * Splits nodes in a tree bin into lower and upper tree bins,
     * or untreeifies if now too small. Called only from resize;
     * see above discussion about split bits and indices.
     *
     * @param map the map
     * @param tab the table for recording bin heads
     * @param index the index of the table being split
     * @param bit the bit of hash to split on
     */
    final void split(HashMap!(K, V) map, HashMapNode!(K, V)[] tab, int index, int bit) {
        TreeNode!(K, V) b = this;
        // Relink into lo and hi lists, preserving order
        TreeNode!(K, V) loHead = null, loTail = null;
        TreeNode!(K, V) hiHead = null, hiTail = null;
        int lc = 0, hc = 0;
        for (TreeNode!(K, V) e = b, next; e !is null; e = next) {
            next = cast(TreeNode!(K, V))e.next;
            e.next = null;
            if ((e.hash & bit) == 0) {
                if ((e.prev = loTail) is null)
                    loHead = e;
                else
                    loTail.next = e;
                loTail = e;
                ++lc;
            }
            else {
                if ((e.prev = hiTail) is null)
                    hiHead = e;
                else
                    hiTail.next = e;
                hiTail = e;
                ++hc;
            }
        }

        if (loHead !is null) {
            if (lc <= UNTREEIFY_THRESHOLD)
                tab[index] = loHead.untreeify(map);
            else {
                tab[index] = loHead;
                if (hiHead !is null) // (else is already treeified)
                    loHead.treeify(tab);
            }
        }
        if (hiHead !is null) {
            if (hc <= UNTREEIFY_THRESHOLD)
                tab[index + bit] = hiHead.untreeify(map);
            else {
                tab[index + bit] = hiHead;
                if (loHead !is null)
                    hiHead.treeify(tab);
            }
        }
    }

    /* ------------------------------------------------------------ */
    // Red-black tree methods, all adapted from CLR

    static TreeNode!(K, V) rotateLeft(K, V)(TreeNode!(K, V) root,
                                          TreeNode!(K, V) p) {
        TreeNode!(K, V) r, pp, rl;
        if (p !is null && (r = p.right) !is null) {
            if ((rl = p.right = r.left) !is null)
                rl.parent = p;
            if ((pp = r.parent = p.parent) is null)
                (root = r).red = false;
            else if (pp.left == p)
                pp.left = r;
            else
                pp.right = r;
            r.left = p;
            p.parent = r;
        }
        return root;
    }

    static TreeNode!(K, V) rotateRight(K, V)(TreeNode!(K, V) root,
                                           TreeNode!(K, V) p) {
        TreeNode!(K, V) l, pp, lr;
        if (p !is null && (l = p.left) !is null) {
            if ((lr = p.left = l.right) !is null)
                lr.parent = p;
            if ((pp = l.parent = p.parent) is null)
                (root = l).red = false;
            else if (pp.right == p)
                pp.right = l;
            else
                pp.left = l;
            l.right = p;
            p.parent = l;
        }
        return root;
    }

    static TreeNode!(K, V) balanceInsertion(K, V)(TreeNode!(K, V) root,
                                                TreeNode!(K, V) x) {
        x.red = true;
        for (TreeNode!(K, V) xp, xpp, xppl, xppr;;) {
            if ((xp = x.parent) is null) {
                x.red = false;
                return x;
            }
            else if (!xp.red || (xpp = xp.parent) is null)
                return root;
            if (xp == (xppl = xpp.left)) {
                if ((xppr = xpp.right) !is null && xppr.red) {
                    xppr.red = false;
                    xp.red = false;
                    xpp.red = true;
                    x = xpp;
                }
                else {
                    if (x == xp.right) {
                        root = rotateLeft(root, x = xp);
                        xpp = (xp = x.parent) is null ? null : xp.parent;
                    }
                    if (xp !is null) {
                        xp.red = false;
                        if (xpp !is null) {
                            xpp.red = true;
                            root = rotateRight(root, xpp);
                        }
                    }
                }
            }
            else {
                if (xppl !is null && xppl.red) {
                    xppl.red = false;
                    xp.red = false;
                    xpp.red = true;
                    x = xpp;
                }
                else {
                    if (x == xp.left) {
                        root = rotateRight(root, x = xp);
                        xpp = (xp = x.parent) is null ? null : xp.parent;
                    }
                    if (xp !is null) {
                        xp.red = false;
                        if (xpp !is null) {
                            xpp.red = true;
                            root = rotateLeft(root, xpp);
                        }
                    }
                }
            }
        }
    }

    static TreeNode!(K, V) balanceDeletion(K, V)(TreeNode!(K, V) root,
                                               TreeNode!(K, V) x) {
        for (TreeNode!(K, V) xp, xpl, xpr;;)  {
            if (x is null || x == root)
                return root;
            else if ((xp = x.parent) is null) {
                x.red = false;
                return x;
            }
            else if (x.red) {
                x.red = false;
                return root;
            }
            else if ((xpl = xp.left) == x) {
                if ((xpr = xp.right) !is null && xpr.red) {
                    xpr.red = false;
                    xp.red = true;
                    root = rotateLeft(root, xp);
                    xpr = (xp = x.parent) is null ? null : xp.right;
                }
                if (xpr is null)
                    x = xp;
                else {
                    TreeNode!(K, V) sl = xpr.left, sr = xpr.right;
                    if ((sr is null || !sr.red) &&
                        (sl is null || !sl.red)) {
                        xpr.red = true;
                        x = xp;
                    }
                    else {
                        if (sr is null || !sr.red) {
                            if (sl !is null)
                                sl.red = false;
                            xpr.red = true;
                            root = rotateRight(root, xpr);
                            xpr = (xp = x.parent) is null ?
                                null : xp.right;
                        }
                        if (xpr !is null) {
                            xpr.red = (xp is null) ? false : xp.red;
                            if ((sr = xpr.right) !is null)
                                sr.red = false;
                        }
                        if (xp !is null) {
                            xp.red = false;
                            root = rotateLeft(root, xp);
                        }
                        x = root;
                    }
                }
            }
            else { // symmetric
                if (xpl !is null && xpl.red) {
                    xpl.red = false;
                    xp.red = true;
                    root = rotateRight(root, xp);
                    xpl = (xp = x.parent) is null ? null : xp.left;
                }
                if (xpl is null)
                    x = xp;
                else {
                    TreeNode!(K, V) sl = xpl.left, sr = xpl.right;
                    if ((sl is null || !sl.red) &&
                        (sr is null || !sr.red)) {
                        xpl.red = true;
                        x = xp;
                    }
                    else {
                        if (sl is null || !sl.red) {
                            if (sr !is null)
                                sr.red = false;
                            xpl.red = true;
                            root = rotateLeft(root, xpl);
                            xpl = (xp = x.parent) is null ?
                                null : xp.left;
                        }
                        if (xpl !is null) {
                            xpl.red = (xp is null) ? false : xp.red;
                            if ((sl = xpl.left) !is null)
                                sl.red = false;
                        }
                        if (xp !is null) {
                            xp.red = false;
                            root = rotateRight(root, xp);
                        }
                        x = root;
                    }
                }
            }
        }
    }

    /**
     * Recursive invariant check
     */
    static bool checkInvariants(K, V)(TreeNode!(K, V) t) {
        TreeNode!(K, V) tp = t.parent, tl = t.left, tr = t.right,
            tb = t.prev, tn = cast(TreeNode!(K, V))t.next;
        if (tb !is null && tb.next != t)
            return false;
        if (tn !is null && tn.prev != t)
            return false;
        if (tp !is null && t != tp.left && t != tp.right)
            return false;
        if (tl !is null && (tl.parent != t || tl.hash > t.hash))
            return false;
        if (tr !is null && (tr.parent != t || tr.hash < t.hash))
            return false;
        if (t.red && tl !is null && tl.red && tr !is null && tr.red)
            return false;
        if (tl !is null && !checkInvariants(tl))
            return false;
        if (tr !is null && !checkInvariants(tr))
            return false;
        return true;
    }
}

    
/**
* Basic hash bin node, used for most entries.  (See below for
* TreeNode subclass, and in LinkedHashMap for its Entry subclass.)
*/
class HashMapNode(K, V) : MapEntry!(K, V) {
    package size_t hash;
    package K key;
    package V value;
    package HashMapNode!(K, V) next;

    this(size_t hash, K key, V value, HashMapNode!(K, V) next) {
        this.hash = hash;
        this.key = key;
        this.value = value;
        this.next = next;
    }

    final K getKey()        { return key; }
    final V getValue()      { return value; }
    final override string toString() { return format("%s=%s", key, value); }

    final override size_t toHash() @trusted nothrow {
        return hashOf(key) ^ hashOf(value);
    }

    final V setValue(V newValue) {
        V oldValue = value;
        value = newValue;
        return oldValue;
    }

    bool opEquals(IObject o) {
        return opEquals(cast(Object) o);
    }

    final override bool opEquals(Object o) {
        if (o is this)
            return true;
            
        MapEntry!(K, V) e = cast(MapEntry!(K, V))o;
        if (e !is null) {
            if (key == e.getKey() && value == e.getValue())
                return true;
        }
        return false;
    }
}


/**
* HashMap.Node subclass for normal LinkedHashMap entries.
*/
static class LinkedHashMapEntry(K, V) : HashMapNode!(K, V) {
    LinkedHashMapEntry!(K, V) before, after;
    this(size_t hash, K key, V value, HashMapNode!(K, V) next) {
        super(hash, key, value, next);
    }
}