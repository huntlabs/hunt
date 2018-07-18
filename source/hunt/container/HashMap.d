module hunt.container.HashMap;

import hunt.container.Map;
import hunt.container.AbstractMap;

import hunt.util.exception;

/**
*/
class HashMap(K,V) : AbstractMap!(K,V)//, Map!(K,V)// , Cloneable //, Serializable
 {

    private enum long serialVersionUID = 362498820763181265L;

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
     * argument (as normally supplied from a public method), allowing
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
     * The bin count threshold for untreeifying a (split) bin during a
     * resize operation. Should be less than TREEIFY_THRESHOLD, and at
     * most 6 to mesh with shrinkage detection under removal.
     */
    enum int UNTREEIFY_THRESHOLD = 6;

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
    static final int hash(K key) {
        return cast(int)hashOf(key);
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
    //         if ((ts = c.getGenericInterfaces()) != null) {
    //             for (int i = 0; i < ts.length; ++i) {
    //                 if (((t = ts[i]) instanceof ParameterizedType) &&
    //                     ((p = (ParameterizedType)t).getRawType() ==
    //                      Comparable.class) &&
    //                     (as = p.getActualTypeArguments()) != null &&
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
    //     return (x == null || x.getClass() != kc ? 0 :
    //             ((Comparable)k).compareTo(x));
    // }

    /**
     * Returns a power of two size for the given target capacity.
     */
    // static final int tableSizeFor(int cap) {
    //     int n = cap - 1;
    //     n |= n >>> 1;
    //     n |= n >>> 2;
    //     n |= n >>> 4;
    //     n |= n >>> 8;
    //     n |= n >>> 16;
    //     return (n < 0) ? 1 : (n >= MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : n + 1;
    // }

    /* ---------------- Fields -------------- */

    /**
     * The table, initialized on first use, and resized as
     * necessary. When allocated, length is always a power of two.
     * (We also tolerate length zero in some operations to allow
     * bootstrapping mechanics that are currently not needed.)
     */
    // Node!(K,V)[] table;

    /**
     * Holds cached entrySet(). Note that AbstractMap fields are used
     * for keySet() and values().
     */
    // Set<Map.Entry!(K,V)> entrySet;

    /**
     * The number of key-value mappings contained in this map.
     */
    // int size;

    /**
     * The number of times this HashMap has been structurally modified
     * Structural modifications are those that change the number of mappings in
     * the HashMap or otherwise modify its internal structure (e.g.,
     * rehash).  This field is used to make iterators on Collection-views of
     * the HashMap fail-fast.  (See ConcurrentModificationException).
     */
    // int modCount;

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
        // if (initialCapacity < 0)
        //     throw new IllegalArgumentException("Illegal initial capacity: " +
        //                                        initialCapacity);
        // if (initialCapacity > MAXIMUM_CAPACITY)
        //     initialCapacity = MAXIMUM_CAPACITY;
        // if (loadFactor <= 0 || Float.isNaN(loadFactor))
        //     throw new IllegalArgumentException("Illegal load factor: " +
        //                                        loadFactor);
        // this.loadFactor = loadFactor;
        // this.threshold = tableSizeFor(initialCapacity);
    }

    /**
     * Constructs an empty <tt>HashMap</tt> with the specified initial
     * capacity and the default load factor (0.75).
     *
     * @param  initialCapacity the initial capacity.
     * @throws IllegalArgumentException if the initial capacity is negative.
     */
    public this(int initialCapacity) {
        this(initialCapacity, DEFAULT_LOAD_FACTOR);
    }

    /**
     * Constructs an empty <tt>HashMap</tt> with the default initial capacity
     * (16) and the default load factor (0.75).
     */
    public this() {
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
    public this(Map!(K, V) m) {
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
        throw new NotImplementedException("");
        // int s = m.size();
        // if (s > 0) {
        //     if (table == null) { // pre-size
        //         float ft = ((float)s / loadFactor) + 1.0F;
        //         int t = ((ft < (float)MAXIMUM_CAPACITY) ?
        //                  (int)ft : MAXIMUM_CAPACITY);
        //         if (t > threshold)
        //             threshold = tableSizeFor(t);
        //     }
        //     else if (s > threshold)
        //         resize();
        //     for (Map.Entry<? extends K, ? extends V> e : m.entrySet()) {
        //         K key = e.getKey();
        //         V value = e.getValue();
        //         putVal(hash(key), key, value, false, evict);
        //     }
        // }
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
        auto v = key in _dict;
        if(v is null)
            return V.init;
        else
            return *v;
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
    // public override V put(K key, V value) {
    //     // return putVal(hash(key), key, value, false, true);
    // }

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
    // final V putVal(int hash, K key, V value, bool onlyIfAbsent,
    //                bool evict) {

    //     assert(false);
    // Node<K,V>[] tab; Node<K,V> p; int n, i;
    //     if ((tab = table) == null || (n = tab.length) == 0)
    //         n = (tab = resize()).length;
    //     if ((p = tab[i = (n - 1) & hash]) == null)
    //         tab[i] = newNode(hash, key, value, null);
    //     else {
    //         Node<K,V> e; K k;
    //         if (p.hash == hash &&
    //             ((k = p.key) == key || (key != null && key.equals(k))))
    //             e = p;
    //         else if (p instanceof TreeNode)
    //             e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
    //         else {
    //             for (int binCount = 0; ; ++binCount) {
    //                 if ((e = p.next) == null) {
    //                     p.next = newNode(hash, key, value, null);
    //                     if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
    //                         treeifyBin(tab, hash);
    //                     break;
    //                 }
    //                 if (e.hash == hash &&
    //                     ((k = e.key) == key || (key != null && key.equals(k))))
    //                     break;
    //                 p = e;
    //             }
    //         }
    //         if (e != null) { // existing mapping for key
    //             V oldValue = e.value;
    //             if (!onlyIfAbsent || oldValue == null)
    //                 e.value = value;
    //             afterNodeAccess(e);
    //             return oldValue;
    //         }
    //     }
    //     ++modCount;
    //     if (++size > threshold)
    //         resize();
    //     afterNodeInsertion(evict);
        // return null;                       
        
    // }

  
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
    // public V remove(Object key) {
    //     Node!(K,V) e;
    //     return (e = removeNode(hash(key), key, null, false, true)) == null ?
    //         null : e.value;
    // }

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
    // final Node!(K,V) removeNode(int hash, Object key, Object value,
    //                            bool matchValue, bool movable) {
    //     Node!(K,V)[] tab; Node!(K,V) p; int n, index;
    //     if ((tab = table) != null && (n = tab.length) > 0 &&
    //         (p = tab[index = (n - 1) & hash]) != null) {
    //         Node!(K,V) node = null, e; K k; V v;
    //         if (p.hash == hash &&
    //             ((k = p.key) == key || (key != null && key.equals(k))))
    //             node = p;
    //         else if ((e = p.next) != null) {
    //             if (p instanceof TreeNode)
    //                 node = ((TreeNode!(K,V))p).getTreeNode(hash, key);
    //             else {
    //                 do {
    //                     if (e.hash == hash &&
    //                         ((k = e.key) == key ||
    //                          (key != null && key.equals(k)))) {
    //                         node = e;
    //                         break;
    //                     }
    //                     p = e;
    //                 } while ((e = e.next) != null);
    //             }
    //         }
    //         if (node != null && (!matchValue || (v = node.value) == value ||
    //                              (value != null && value.equals(v)))) {
    //             if (node instanceof TreeNode)
    //                 ((TreeNode!(K,V))node).removeTreeNode(this, tab, movable);
    //             else if (node == p)
    //                 tab[index] = node.next;
    //             else
    //                 p.next = node.next;
    //             ++modCount;
    //             --size;
    //             afterNodeRemoval(node);
    //             return node;
    //         }
    //     }
    //     return null;
    // }

    /**
     * Removes all of the mappings from this map.
     * The map will be empty after this call returns.
     */
    // public void clear() {
    //     Node!(K,V)[] tab;
    //     modCount++;
    //     if ((tab = table) != null && size > 0) {
    //         size = 0;
    //         for (int i = 0; i < tab.length; ++i)
    //             tab[i] = null;
    //     }
    // }

    /**
     * Returns <tt>true</tt> if this map maps one or more keys to the
     * specified value.
     *
     * @param value value whose presence in this map is to be tested
     * @return <tt>true</tt> if this map maps one or more keys to the
     *         specified value
     */
    // override bool containsValue(V value) {
    //     foreach(k, v; _dict)
    //     {
    //         static if(is(V == class))
    //         {
    //             if(value is v || value == v)
    //                 return true;
    //         }
    //         else
    //         {
    //             if(value == v)
    //                 return true;
    //         }
    //     }
        
    //     return false;
    // }

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
    // public Set<K> keySet() {
    //     Set<K> ks = keySet;
    //     if (ks == null) {
    //         ks = new KeySet();
    //         keySet = ks;
    //     }
    //     return ks;
    // }

    


    // Overrides of JDK8 Map extension methods

    // override
    // public V getOrDefault(Object key, V defaultValue) {
    //     Node!(K,V) e;
    //     return (e = getNode(hash(key), key)) == null ? defaultValue : e.value;
    // }

    // override
    // public V putIfAbsent(K key, V value) {
    //     return putVal(hash(key), key, value, true, true);
    // }

    // override
    // public bool remove(Object key, Object value) {
    //     return removeNode(hash(key), key, value, true, true) != null;
    // }

    // override
    // public bool replace(K key, V oldValue, V newValue) {
    //     Node!(K,V) e; V v;
    //     if ((e = getNode(hash(key), key)) != null &&
    //         ((v = e.value) == oldValue || (v != null && v.equals(oldValue)))) {
    //         e.value = newValue;
    //         afterNodeAccess(e);
    //         return true;
    //     }
    //     return false;
    // }

    // override
    // public V replace(K key, V value) {
    //     Node!(K,V) e;
    //     if ((e = getNode(hash(key), key)) != null) {
    //         V oldValue = e.value;
    //         e.value = value;
    //         afterNodeAccess(e);
    //         return oldValue;
    //     }
    //     return null;
    // }

    // override
    // public V computeIfAbsent(K key,
    //                          Function<? super K, ? extends V> mappingFunction) {
    //     if (mappingFunction == null)
    //         throw new NullPointerException();
    //     int hash = hash(key);
    //     Node!(K,V)[] tab; Node!(K,V) first; int n, i;
    //     int binCount = 0;
    //     TreeNode!(K,V) t = null;
    //     Node!(K,V) old = null;
    //     if (size > threshold || (tab = table) == null ||
    //         (n = tab.length) == 0)
    //         n = (tab = resize()).length;
    //     if ((first = tab[i = (n - 1) & hash]) != null) {
    //         if (first instanceof TreeNode)
    //             old = (t = (TreeNode!(K,V))first).getTreeNode(hash, key);
    //         else {
    //             Node!(K,V) e = first; K k;
    //             do {
    //                 if (e.hash == hash &&
    //                     ((k = e.key) == key || (key != null && key.equals(k)))) {
    //                     old = e;
    //                     break;
    //                 }
    //                 ++binCount;
    //             } while ((e = e.next) != null);
    //         }
    //         V oldValue;
    //         if (old != null && (oldValue = old.value) != null) {
    //             afterNodeAccess(old);
    //             return oldValue;
    //         }
    //     }
    //     V v = mappingFunction.apply(key);
    //     if (v == null) {
    //         return null;
    //     } else if (old != null) {
    //         old.value = v;
    //         afterNodeAccess(old);
    //         return v;
    //     }
    //     else if (t != null)
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

    // public V computeIfPresent(K key,
    //                           BiFunction<? super K, ? super V, ? extends V> remappingFunction) {
    //     if (remappingFunction == null)
    //         throw new NullPointerException();
    //     Node!(K,V) e; V oldValue;
    //     int hash = hash(key);
    //     if ((e = getNode(hash, key)) != null &&
    //         (oldValue = e.value) != null) {
    //         V v = remappingFunction.apply(key, oldValue);
    //         if (v != null) {
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
    // public V compute(K key,
    //                  BiFunction<? super K, ? super V, ? extends V> remappingFunction) {
    //     if (remappingFunction == null)
    //         throw new NullPointerException();
    //     int hash = hash(key);
    //     Node!(K,V)[] tab; Node!(K,V) first; int n, i;
    //     int binCount = 0;
    //     TreeNode!(K,V) t = null;
    //     Node!(K,V) old = null;
    //     if (size > threshold || (tab = table) == null ||
    //         (n = tab.length) == 0)
    //         n = (tab = resize()).length;
    //     if ((first = tab[i = (n - 1) & hash]) != null) {
    //         if (first instanceof TreeNode)
    //             old = (t = (TreeNode!(K,V))first).getTreeNode(hash, key);
    //         else {
    //             Node!(K,V) e = first; K k;
    //             do {
    //                 if (e.hash == hash &&
    //                     ((k = e.key) == key || (key != null && key.equals(k)))) {
    //                     old = e;
    //                     break;
    //                 }
    //                 ++binCount;
    //             } while ((e = e.next) != null);
    //         }
    //     }
    //     V oldValue = (old == null) ? null : old.value;
    //     V v = remappingFunction.apply(key, oldValue);
    //     if (old != null) {
    //         if (v != null) {
    //             old.value = v;
    //             afterNodeAccess(old);
    //         }
    //         else
    //             removeNode(hash, key, null, false, true);
    //     }
    //     else if (v != null) {
    //         if (t != null)
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
    // public V merge(K key, V value,
    //                BiFunction<? super V, ? super V, ? extends V> remappingFunction) {
    //     if (value == null)
    //         throw new NullPointerException();
    //     if (remappingFunction == null)
    //         throw new NullPointerException();
    //     int hash = hash(key);
    //     Node!(K,V)[] tab; Node!(K,V) first; int n, i;
    //     int binCount = 0;
    //     TreeNode!(K,V) t = null;
    //     Node!(K,V) old = null;
    //     if (size > threshold || (tab = table) == null ||
    //         (n = tab.length) == 0)
    //         n = (tab = resize()).length;
    //     if ((first = tab[i = (n - 1) & hash]) != null) {
    //         if (first instanceof TreeNode)
    //             old = (t = (TreeNode!(K,V))first).getTreeNode(hash, key);
    //         else {
    //             Node!(K,V) e = first; K k;
    //             do {
    //                 if (e.hash == hash &&
    //                     ((k = e.key) == key || (key != null && key.equals(k)))) {
    //                     old = e;
    //                     break;
    //                 }
    //                 ++binCount;
    //             } while ((e = e.next) != null);
    //         }
    //     }
    //     if (old != null) {
    //         V v;
    //         if (old.value != null)
    //             v = remappingFunction.apply(old.value, value);
    //         else
    //             v = value;
    //         if (v != null) {
    //             old.value = v;
    //             afterNodeAccess(old);
    //         }
    //         else
    //             removeNode(hash, key, null, false, true);
    //         return v;
    //     }
    //     if (value != null) {
    //         if (t != null)
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


   
}