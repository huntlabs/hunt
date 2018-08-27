module hunt.security.util.Cache;

import hunt.container;

import hunt.util.exception;
import hunt.util.memory;

import std.conv;
import std.datetime;

import hunt.logger;

/**
 * Abstract base class and factory for caches. A cache is a key-value mapping.
 * It has properties that make it more suitable for caching than a Map.
 *
 * The factory methods can be used to obtain two different implementations.
 * They have the following properties:
 *
 *  . keys and values reside in memory
 *
 *  . keys and values must be non-null
 *
 *  . maximum size. Replacements are made in LRU order.
 *
 *  . optional lifetime, specified in seconds.
 *
 *  . safe for concurrent use by multiple threads
 *
 *  . values are held by either standard references or via SoftReferences.
 *    SoftReferences have the advantage that they are automatically cleared
 *    by the garbage collector in response to memory demand. This makes it
 *    possible to simple set the maximum size to a very large value and let
 *    the GC automatically size the cache dynamically depending on the
 *    amount of available memory.
 *
 * However, note that because of the way SoftReferences are implemented in
 * HotSpot at the moment, this may not work perfectly as it clears them fairly
 * eagerly. Performance may be improved if the Java heap size is set to larger
 * value using e.g. java -ms64M -mx128M foo.Test
 *
 * Cache sizing: the memory cache is implemented on top of a LinkedHashMap.
 * In its current implementation, the number of buckets (NOT entries) in
 * (Linked)HashMaps is always a power of two. It is recommended to set the
 * maximum cache size to value that uses those buckets fully. For example,
 * if a cache with somewhere between 500 and 1000 entries is desired, a
 * maximum size of 750 would be a good choice: try 1024 buckets, with a
 * load factor of 0.75f, the number of entries can be calculated as
 * buckets / 4 * 3. As mentioned above, with a SoftReference cache, it is
 * generally reasonable to set the size to a fairly large value.
 *
 * @author Andreas Sterbenz
 */
abstract class Cache(K,V) {

    protected this() {
        // empty
    }

    /**
     * Return the number of currently valid entries in the cache.
     */
    abstract int size();

    /**
     * Remove all entries from the cache.
     */
    abstract void clear();

    /**
     * Add an entry to the cache.
     */
    abstract void put(K key, V value);

    /**
     * Get a value from the cache.
     */
    abstract V get(K key);

    /**
     * Remove an entry from the cache.
     */
    abstract void remove(K key);

    /**
     * Set the maximum size.
     */
    abstract void setCapacity(int size);

    /**
     * Set the timeout(in seconds).
     */
    abstract void setTimeout(int timeout);

    /**
     * accept a visitor
     */
    abstract void accept(CacheVisitor!(K, V) visitor);

    interface CacheVisitor(K, V) {
        void visit(Map!(K, V) map);
    }

}

/**
* Utility class that wraps a byte array and implements the equals()
* and hashCode() contract in a way suitable for Maps and caches.
*/
static class EqualByteArray {

    private byte[] b;
    private size_t hash;

    this(byte[] b) {
        this.b = b;
        hash = 0;
    }

    override size_t toHash() @trusted nothrow {
        size_t h = hash;
        if (h == 0) {
            h = b.length + 1;
            for (size_t i = 0; i < b.length; i++) {
                h += (b[i] & 0xff) * 37;
            }
            hash = h;
        }
        return h;
    }

    override bool opEquals(Object obj) {
        if (this is obj) {
            return true;
        }
        if (obj is null) {
            return false;
        }
        EqualByteArray other = cast(EqualByteArray)obj;
        if(other is null)
            return false;
        return this.b == other.b;
    }
}


class NullCache(K, V) : Cache!(K, V) {

    __gshared static Cach!(K, V) INSTANCE;

    shared static this()
    {
        INSTANCE = new NullCache!(K, V)();
    }

    private this() {
        // empty
    }

    int size() {
        return 0;
    }

    void clear() {
        // empty
    }

    void put(K key, V value) {
        // empty
    }

    V get(K key) {
        return null;
    }

    void remove(K key) {
        // empty
    }

    void setCapacity(int size) {
        // empty
    }

    void setTimeout(int timeout) {
        // empty
    }

    void accept(CacheVisitor!(K, V) visitor) {
        // empty
    }

}


/**
*/
class MemoryCache(K, V) : Cache!(K, V) {

    private enum float LOAD_FACTOR = 0.75f;

    // XXXX
    // private final static bool DEBUG = false;

    private Map!(K, CacheEntry!(K, V)) cacheMap;
    private int maxSize;
    private long lifetime;

    // ReferenceQueue is of type V instead of Cache!(K, V)
    // to allow SoftCacheEntry to extend SoftReference<V>
    private ReferenceQueue!V queue;

    this(bool soft, int maxSize) {
        this(soft, maxSize, 0);
    }

    this(bool soft, int maxSize, int lifetime) {
        this.maxSize = maxSize;
        this.lifetime = lifetime * 1000;
        // if (soft)
        //     this.queue = new ReferenceQueue<>();
        // else
            this.queue = null;

        int buckets = cast(int)(maxSize / LOAD_FACTOR) + 1;
        cacheMap = new LinkedHashMap!(K, CacheEntry!(K, V))(buckets, LOAD_FACTOR, true);
    }

    /**
     * Empty the reference queue and remove all corresponding entries
     * from the cache.
     *
     * This method should be called at the beginning of each public
     * method.
     */
    private void emptyQueue() {
        // if (queue is null) {
        //     return;
        // }
        // int startSize = cacheMap.size();
        // while (true) {
        //     CacheEntry!(K, V) entry = (CacheEntry!(K, V))queue.poll();
        //     if (entry is null) {
        //         break;
        //     }
        //     K key = entry.getKey();
        //     if (key is null) {
        //         // key is null, entry has already been removed
        //         continue;
        //     }
        //     CacheEntry!(K, V) currentEntry = cacheMap.remove(key);
        //     // check if the entry in the map corresponds to the expired
        //     // entry. If not, readd the entry
        //     if ((currentEntry !is null) && (entry != currentEntry)) {
        //         cacheMap.put(key, currentEntry);
        //     }
        // }
        // version(HuntDebugMode) {
        //     int endSize = cacheMap.size();
        //     if (startSize != endSize) {
        //         trace("*** Expunged " ~ to!string(startSize - endSize)
        //                 ~ " entries, " ~ endSize.to!string() ~ " entries left");
        //     }
        // }
    }

    /**
     * Scan all entries and remove all expired ones.
     */
    private void expungeExpiredEntries() {
        emptyQueue();
        if (lifetime == 0) {
            return;
        }
        int cnt = 0;
        long time = Clock.currStdTime;
        // foreach (CacheEntry!(K, V) entry; cacheMap.values()) {
        //     if (entry.isValid(time) == false) {
        //         t.remove();
        //         cnt++;
        //     }
        // }
        implementationMissing();
        version(HuntDebugMode)  {
            if (cnt != 0) {
                trace("Removed " ~ cnt.to!string()
                        ~ " expired entries, remaining " ~ cacheMap.size().to!string());
            }
        }
    }

    override int size() {
        expungeExpiredEntries();
        return cacheMap.size();
    }

    override void clear() {
        if (queue !is null) {
            // if this is a SoftReference cache, first invalidate() all
            // entries so that GC does not have to enqueue them
            foreach (CacheEntry!(K, V) entry ; cacheMap.values()) {
                entry.invalidate();
            }
            // while (queue.poll() !is null) {
            //     // empty
            // }
        }
        cacheMap.clear();
    }

    override void put(K key, V value) {
        emptyQueue();
        long expirationTime = (lifetime == 0) ? 0 :
                                       Clock.currStdTime + lifetime;
        CacheEntry!(K, V) newEntry = newEntry(key, value, expirationTime, queue);
        CacheEntry!(K, V) oldEntry = cacheMap.put(key, newEntry);
        if (oldEntry !is null) {
            oldEntry.invalidate();
            return;
        }
        if (maxSize > 0 && cacheMap.size() > maxSize) {
            expungeExpiredEntries();
            if (cacheMap.size() > maxSize) { // still too large?
                // Iterator<CacheEntry!(K, V)> t = cacheMap.values().iterator();
                // CacheEntry!(K, V) lruEntry = t.next();
                // foreach(CacheEntry!(K, V) lruEntry; cacheMap.values())
                // {
                //     version(HuntDebugMode)  {
                //         tracef("** Overflow removal "
                //             + lruEntry.getKey() ~ " | " ~ lruEntry.getValue());
                //     }
                //     t.remove();
                //     lruEntry.invalidate();
                //     break;
                // }

        implementationMissing();
            }
        }
    }

    override V get(K key) {
        emptyQueue();
        CacheEntry!(K, V) entry = cacheMap.get(key);
        if (entry is null) {
            return null;
        }
        long time = (lifetime == 0) ? 0 :Clock.currStdTime;
        if (entry.isValid(time) == false) {
            version(HuntDebugMode)  {
                tracef("Ignoring expired entry");
            }
            cacheMap.remove(key);
            return null;
        }
        return entry.getValue();
    }

    override void remove(K key) {
        emptyQueue();
        CacheEntry!(K, V) entry = cacheMap.remove(key);
        if (entry !is null) {
            entry.invalidate();
        }
    }

    override void setCapacity(int size) {
        expungeExpiredEntries();
        // TODO: Tasks pending completion -@zxp at 8/10/2018, 4:50:39 PM
        // 
        implementationMissing();
        // if (size > 0 && cacheMap.size() > size) {
        //     // Iterator<CacheEntry!(K, V)> t = cacheMap.values().iterator();
        //     // for (int i = cacheMap.size() - size; i > 0; i--) {
        //     int i = cacheMap.size() - size;
        //     foreach(CacheEntry!(K, V) lruEntry; cacheMap.values())
        //         version(HuntDebugMode)  {
        //             tracef("** capacity reset removal "
        //                 + lruEntry.getKey() ~ " | " ~ lruEntry.getValue());
        //         }
        //         // t.remove();
        //         cacheMap.remove()
        //         lruEntry.invalidate();
        //         i--; 
        //         if(i <= 0)  break;
        //     }
        // }

        maxSize = size > 0 ? size : 0;

        version(HuntDebugMode)  {
            tracef("** capacity reset to " ~ size.to!string());
        }
    }

    override void setTimeout(int timeout) {
        emptyQueue();
        lifetime = timeout > 0 ? timeout * 1000L : 0L;

        version(HuntDebugMode)  {
            tracef("** lifetime reset to " ~ timeout.to!string());
        }
    }

    // it is a heavyweight method.
    override void accept(CacheVisitor!(K, V) visitor) {
        expungeExpiredEntries();
        Map!(K, V) cached = getCachedEntries();

        visitor.visit(cached);
    }

    private Map!(K, V) getCachedEntries() {
        Map!(K, V) kvmap = new HashMap!(K, V)(cacheMap.size());

        foreach (CacheEntry!(K, V) entry ; cacheMap.values()) {
            kvmap.put(entry.getKey(), entry.getValue());
        }

        return kvmap;
    }

    protected CacheEntry!(K, V) newEntry(K key, V value,
            long expirationTime, ReferenceQueue!V queue) {
        // if (queue !is null) {
        //     return new SoftCacheEntry!V(key, value, expirationTime, queue);
        // } else {
            return new HardCacheEntry!(K, V)(key, value, expirationTime);
        // }
    }

    private static interface CacheEntry(K, V) {

        bool isValid(long currentTime);

        void invalidate();

        K getKey();

        V getValue();

    }

    private static class HardCacheEntry(K, V) : CacheEntry!(K, V) {

        private K key;
        private V value;
        private long expirationTime;

        this(K key, V value, long expirationTime) {
            this.key = key;
            this.value = value;
            this.expirationTime = expirationTime;
        }

        K getKey() {
            return key;
        }

        V getValue() {
            return value;
        }

        bool isValid(long currentTime) {
            bool valid = (currentTime <= expirationTime);
            if (valid == false) {
                invalidate();
            }
            return valid;
        }

        void invalidate() {
            key = null;
            value = null;
            expirationTime = -1;
        }
    }

    // private static class SoftCacheEntry(K, V)
    //         : //SoftReference<V>
    //         CacheEntry!(K, V) {

    //     private K key;
    //     private long expirationTime;

    //     this(K key, V value, long expirationTime,
    //             ReferenceQueue<V> queue) {
    //         super(value, queue);
    //         this.key = key;
    //         this.expirationTime = expirationTime;
    //     }

    //     K getKey() {
    //         return key;
    //     }

    //     V getValue() {
    //         return get();
    //     }

    //     bool isValid(long currentTime) {
    //         bool valid = (currentTime <= expirationTime) && (get() !is null);
    //         if (valid == false) {
    //             invalidate();
    //         }
    //         return valid;
    //     }

    //     void invalidate() {
    //         clear();
    //         key = null;
    //         expirationTime = -1;
    //     }
    // }

}



    /**
     * Return a new memory cache with the specified maximum size, unlimited
     * lifetime for entries, with the values held by SoftReferences.
     */
    static Cache!(K, V) newSoftMemoryCache(K, V)(int size) {
        return new MemoryCache!(K, V)(true, size);
    }

    /**
     * Return a new memory cache with the specified maximum size, the
     * specified maximum lifetime (in seconds), with the values held
     * by SoftReferences.
     */
    static Cache!(K, V) newSoftMemoryCache(K, V)(int size, int timeout) {
        return new MemoryCache!(K, V)(true, size, timeout);
    }

    /**
     * Return a new memory cache with the specified maximum size, unlimited
     * lifetime for entries, with the values held by standard references.
     */
    static Cache!(K, V) newHardMemoryCache(K, V)(int size) {
        return new MemoryCache!(K, V)(false, size);
    }

    /**
     * Return a dummy cache that does nothing.
     */
    static Cache!(K, V) newNullCache(K, V)() {
        return NullCache!(K, V).INSTANCE;
    }

    /**
     * Return a new memory cache with the specified maximum size, the
     * specified maximum lifetime (in seconds), with the values held
     * by standard references.
     */
    static Cache!(K, V) newHardMemoryCache(K, V)(int size, int timeout) {
        return new MemoryCache!(K, V)(false, size, timeout);
    }
