module hunt.container.ArrayTernaryTrie;

import hunt.container.AbstractMap;
import hunt.container.AbstractTrie;
import hunt.container.ByteBuffer;
import hunt.container.HashSet;
import hunt.container.Set;
import hunt.container.Trie;

import hunt.util.exception;
import hunt.util.string;

import std.ascii;
import std.conv;

/**
 * <p>A Ternary Trie string lookup data structure.</p>
 * <p>
 * This Trie is of a fixed size and cannot grow (which can be a good thing with regards to DOS when used as a cache).
 * </p>
 * <p>
 * The Trie is stored in 3 arrays:
 * </p>
 * <dl>
 * <dt>char[] _tree</dt><dd>This is semantically 2 dimensional array flattened into a 1 dimensional char array. The second dimension
 * is that every 4 sequential elements represents a row of: character; hi index; eq index; low index, used to build a
 * ternary trie of key strings.</dd>
 * <dt>string[] _key</dt><dd>An array of key values where each element matches a row in the _tree array. A non zero key element
 * indicates that the _tree row is a complete key rather than an intermediate character of a longer key.</dd>
 * <dt>V[] _value</dt><dd>An array of values corresponding to the _key array</dd>
 * </dl>
 * <p>The lookup of a value will iterate through the _tree array matching characters. If the equal tree branch is followed,
 * then the _key array is looked up to see if this is a complete match.  If a match is found then the _value array is looked up
 * to return the matching value.
 * </p>
 * <p>
 * This Trie may be instantiated either as case sensitive or insensitive.
 * </p>
 * <p>This Trie is not Threadsafe and contains no mutual exclusion
 * or deliberate memory barriers.  It is intended for an ArrayTrie to be
 * built by a single thread and then used concurrently by multiple threads
 * and not mutated during that access.  If concurrent mutations of the
 * Trie is required external locks need to be applied.
 * </p>
 *
 * @param !(V) the Entry type
 */
class ArrayTernaryTrie(V) : AbstractTrie!(V) {
    private enum int LO = 1;
    private enum int EQ = 2;
    private enum int HI = 3;

    /**
     * The Size of a Trie row is the char, and the low, equal and high
     * child pointers
     */
    private enum int ROW_SIZE = 4;

    /**
     * The Trie rows in a single array which allows a lookup of row,character
     * to the next row in the Trie.  This is actually a 2 dimensional
     * array that has been flattened to achieve locality of reference.
     */
    private byte[] _tree;

    /**
     * The key (if any) for a Trie row.
     * A row may be a leaf, a node or both in the Trie tree.
     */
    private string[] _key;

    /**
     * The value (if any) for a Trie row.
     * A row may be a leaf, a node or both in the Trie tree.
     */
    private V[] _value;

    /**
     * The number of rows allocated
     */
    private char _rows;

    /* ------------------------------------------------------------ */

    /**
     * Create a case insensitive Trie of default capacity.
     */
    this() {
        this(128);
    }

    /* ------------------------------------------------------------ */

    /**
     * Create a Trie of default capacity
     *
     * @param insensitive true if the Trie is insensitive to the case of the key.
     */
    this(bool insensitive) {
        this(insensitive, 128);
    }

    /* ------------------------------------------------------------ */

    /**
     * Create a case insensitive Trie
     *
     * @param capacity The capacity of the Trie, which is in the worst case
     *                 is the total number of characters of all keys stored in the Trie.
     *                 The capacity needed is dependent of the shared prefixes of the keys.
     *                 For example, a capacity of 6 nodes is required to store keys "foo"
     *                 and "bar", but a capacity of only 4 is required to
     *                 store "bar" and "bat".
     */
    this(int capacity) {
        this(true, capacity);
    }

    /* ------------------------------------------------------------ */

    /**
     * Create a Trie
     *
     * @param insensitive true if the Trie is insensitive to the case of the key.
     * @param capacity    The capacity of the Trie, which is in the worst case
     *                    is the total number of characters of all keys stored in the Trie.
     *                    The capacity needed is dependent of the shared prefixes of the keys.
     *                    For example, a capacity of 6 nodes is required to store keys "foo"
     *                    and "bar", but a capacity of only 4 is required to
     *                    store "bar" and "bat".
     */
    this(bool insensitive, int capacity) {
        super(insensitive);
        _value = new V[capacity];
        _tree = new byte[capacity * ROW_SIZE];
        _key = new string[capacity];
    }

    /* ------------------------------------------------------------ */

    /**
     * Copy Trie and change capacity by a factor
     *
     * @param trie   the trie to copy from
     * @param factor the factor to grow the capacity by
     */
    this(ArrayTernaryTrie!(V) trie, double factor) {
        super(trie.isCaseInsensitive());
        size_t capacity = cast(size_t) (trie._value.length * factor);
        _rows = trie._rows;
        _value = new V[capacity];
        _tree = new byte[capacity * ROW_SIZE];
        _key = new string[capacity];

        import std.algorithm;
        size_t actualLength = min(_value.length, trie._value.length);
        _value[0 .. actualLength] = trie._value[0 .. actualLength];

        actualLength = min(_tree.length, trie._tree.length);
        _tree[0 .. actualLength] = trie._tree[0 .. actualLength];

        actualLength = min(_key.length, trie._key.length);
        _key[0 .. actualLength] = trie._key[0 .. actualLength];
    }

    /* ------------------------------------------------------------ */
    override
    void clear() {
        _rows = 0;
        _value[] = V.init;
        _tree[] = 0;
        _key[] = null;
    }

    /* ------------------------------------------------------------ */
    override
    bool put(string s, V v) {
        int t = 0;
        size_t limit = s.length;
        int last = 0;
        for (size_t k = 0; k < limit; k++) {
            char c = s[k];
            if (isCaseInsensitive() && c < 128)
                c = toLower(c);

            while (true) {
                int row = ROW_SIZE * t;

                // Do we need to create the new row?
                if (t == _rows) {
                    _rows++;
                    if (_rows >= _key.length) {
                        _rows--;
                        return false;
                    }
                    _tree[row] = c;
                }

                char n = _tree[row];
                int diff = n - c;
                if (diff == 0)
                    t = _tree[last = (row + EQ)];
                else if (diff < 0)
                    t = _tree[last = (row + LO)];
                else
                    t = _tree[last = (row + HI)];

                // do we need a new row?
                if (t == 0) {
                    t = _rows;
                    _tree[last] = cast(byte) t;
                }

                if (diff == 0)
                    break;
            }
        }

        // Do we need to create the new row?
        if (t == _rows) {
            _rows++;
            if (_rows >= _key.length) {
                _rows--;
                return false;
            }
        }

        // Put the key and value
        static if(is(V == class)) {
            _key[t] = v is null ? null : s;
        } else {
            _key[t] = v == V.init ? null : s;
        }
        
        _value[t] = v;

        return true;
    }


    /* ------------------------------------------------------------ */
    override
    V get(string s, int offset, int len) {
        int t = 0;
        for (int i = 0; i < len; ) {
            char c = s.charAt(offset + i++);
            if (isCaseInsensitive() && c < 128)
                c = toLower(c);

            while (true) {
                int row = ROW_SIZE * t;
                char n = _tree[row];
                int diff = n - c;

                if (diff == 0) {
                    t = _tree[row + EQ];
                    if (t == 0)
                        return V.init;
                    break;
                }

                t = _tree[row + hilo(diff)];
                if (t == 0)
                    return V.init;
            }
        }

        return _value[t];
    }


    override
    V get(ByteBuffer b, int offset, int len) {
        int t = 0;
        offset += b.position();

        for (int i = 0; i < len; ) {
            byte c = cast(byte) (b.get(offset + i++) & 0x7f);
            if (isCaseInsensitive())
                c = cast(byte) toLower(c);

            while (true) {
                int row = ROW_SIZE * t;
                char n = _tree[row];
                int diff = n - c;

                if (diff == 0) {
                    t = _tree[row + EQ];
                    if (t == 0)
                        return V.init;
                    break;
                }

                t = _tree[row + hilo(diff)];
                if (t == 0)
                    return V.init;
            }
        }

        return _value[t];
    }

    /* ------------------------------------------------------------ */
    override
    V getBest(string s) {
        return getBest(0, s, 0, cast(int)s.length);
    }

    /* ------------------------------------------------------------ */
    override
    V getBest(string s, int offset, int length) {
        return getBest(0, s, offset, length);
    }

    /* ------------------------------------------------------------ */
    private V getBest(int t, string s, int offset, int len) {
        int node = t;
        int end = offset + len;
        loop:
        while (offset < end) {
            char c = s.charAt(offset++);
            len--;
            if (isCaseInsensitive() && c < 128)
                c = toLower(c);

            while (true) {
                int row = ROW_SIZE * t;
                char n = _tree[row];
                int diff = n - c;

                if (diff == 0) {
                    t = _tree[row + EQ];
                    if (t == 0)
                        break loop;

                    // if this node is a match, recurse to remember
                    if (_key[t] !is null) {
                        node = t;
                        V best = getBest(t, s, offset, len);
                        static if(is(V == class)) {
                            if (best !is null)
                                return best;
                        } else {
                            if (best != V.init)
                                return best;
                        }
                    }
                    break;
                }

                t = _tree[row + hilo(diff)];
                if (t == 0)
                    break loop;
            }
        }
        return _value[node];
    }


    /* ------------------------------------------------------------ */
    override
    V getBest(ByteBuffer b, int offset, int len) {
        if (b.hasArray())
            return getBest(0, b.array(), b.arrayOffset() + b.position() + offset, len);
        return getBest(0, b, offset, len);
    }

    /* ------------------------------------------------------------ */
    private V getBest(int t, byte[] b, int offset, int len) {
        int node = t;
        int end = offset + len;
        loop:
        while (offset < end) {
            byte c = cast(byte) (b[offset++] & 0x7f);
            len--;
            if (isCaseInsensitive())
                c = cast(byte) toLower(c);

            while (true) {
                int row = ROW_SIZE * t;
                char n = _tree[row];
                int diff = n - c;

                if (diff == 0) {
                    t = _tree[row + EQ];
                    if (t == 0)
                        break loop;

                    // if this node is a match, recurse to remember
                    if (_key[t] !is null) {
                        node = t;
                        V best = getBest(t, b, offset, len);
                        static if(is(V == class)) {
                        if (best !is null)
                            return best;
                        } else {
                            if (best != V.init)
                                return best;
                        }
                    }
                    break;
                }

                t = _tree[row + hilo(diff)];
                if (t == 0)
                    break loop;
            }
        }
        return _value[node];
    }

    /* ------------------------------------------------------------ */
    private V getBest(int t, ByteBuffer b, int offset, int len) {
        int node = t;
        int o = offset + b.position();

        loop:
        for (int i = 0; i < len; i++) {
            byte c = cast(byte) (b.get(o + i) & 0x7f);
            if (isCaseInsensitive())
                c = cast(byte) toLower(c);

            while (true) {
                int row = ROW_SIZE * t;
                char n = _tree[row];
                int diff = n - c;

                if (diff == 0) {
                    t = _tree[row + EQ];
                    if (t == 0)
                        break loop;

                    // if this node is a match, recurse to remember
                    if (_key[t] !is null) {
                        node = t;
                        V best = getBest(t, b, offset + i + 1, len - i - 1);
                        
                        static if(is(V == class)) {
                            if (best !is null)
                                return best;
                        } else {
                            if (best != V.init)
                                return best;
                        }
                    }
                    break;
                }

                t = _tree[row + hilo(diff)];
                if (t == 0)
                    break loop;
            }
        }
        return _value[node];
    }

    override
    string toString() {
        StringBuilder buf = new StringBuilder();
        for (int r = 0; r <= _rows; r++) {
            static if(is(V == class)) {                
                if (_key[r] !is null && _value[r] !is null) {
                    buf.append(',');
                    buf.append(_key[r]);
                    buf.append('=');
                    buf.append(_value[r].to!string());
                }
            } else { 
                if (_key[r] !is null && _value[r] != V.init) {
                    buf.append(',');
                    buf.append(_key[r]);
                    buf.append('=');
                    buf.append(_value[r].to!string());
                }
            }
        }
        if (buf.length() == 0)
            return "{}";

        buf.setCharAt(0, '{');
        buf.append('}');
        return buf.toString();
    }


    override
    Set!(string) keySet() {
        Set!(string) keys = new HashSet!string();

        for (int r = 0; r <= _rows; r++) {
            static if(is(V == class)) {
                if (_key[r] !is null && _value[r] !is null)
                    keys.add(_key[r]);
            } else {
                if (_key[r] !is null && _value[r] != V.init)
                    keys.add(_key[r]);
            }
        }
        return keys;
    }

    int size() {
        int s = 0;
        for (int r = 0; r <= _rows; r++) {
            
            static if(is(V == class)) {
                if (_key[r] !is null && _value[r] !is null)
                    s++;
            } else {
                if (_key[r] !is null && _value[r] != V.init)
                    s++;
            }

        }
        return s;
    }

    bool isEmpty() {
        for (int r = 0; r <= _rows; r++) {
            static if(is(V == class)) {
                if (_key[r] !is null && _value[r] !is null)
                    return false;
            } else {
                if (_key[r] !is null && _value[r] != V.init)
                    return false;
            }
        }
        return true;
    }


    // Set<Map.Entry<string, V>> entrySet() {
    //     Set<Map.Entry<string, V>> entries = new HashSet<>();
    //     for (int r = 0; r <= _rows; r++) {
    //         if (_key[r] !is null && _value[r] !is null)
    //             entries.add(new AbstractMap.SimpleEntry<>(_key[r], _value[r]));
    //     }
    //     return entries;
    // }

    override
    bool isFull() {
        return _rows + 1 == _key.length;
    }

    static int hilo(int diff) {
        // branchless equivalent to return ((diff<0)?LO:HI);
        // return 3+2*((diff&Integer.MIN_VALUE)>>Integer.SIZE-1);
        return 1 + (diff | int.max) / (int.max / 2);
    }

    void dump() {
        import std.stdio;
        for (int r = 0; r < _rows; r++) {
            char c = _tree[r * ROW_SIZE + 0];
            writefln("%4d [%s,%d,%d,%d] '%s':%s%n",
                    r,
                    (c < ' ' || c > 127) ? to!string(cast(int) c) : "'" ~ c ~ "'",
                    cast(int) _tree[r * ROW_SIZE + LO],
                    cast(int) _tree[r * ROW_SIZE + EQ],
                    cast(int) _tree[r * ROW_SIZE + HI],
                    _key[r],
                    _value[r]);
        }

    }
}


class Growing(V) : Trie!(V) {
    private int _growby;
    private ArrayTernaryTrie!(V) _trie;

    this() {
        this(1024, 1024);
    }

    this(int capacity, int growby) {
        _growby = growby;
        _trie = new ArrayTernaryTrie!V(capacity);
    }

    this(bool insensitive, int capacity, int growby) {
        _growby = growby;
        _trie = new ArrayTernaryTrie!V(insensitive, capacity);
    }

    bool put(V v) {
        return put(v.toString(), v);
    }

    int hashCode() {
        return _trie.hashCode();
    }

    V remove(string s) {
        return _trie.remove(s);
    }

    V get(string s) {
        return _trie.get(s);
    }

    V get(ByteBuffer b) {
        return _trie.get(b);
    }

    V getBest(byte[] b, int offset, int len) {
        return _trie.getBest(b, offset, len);
    }

    bool isCaseInsensitive() {
        return _trie.isCaseInsensitive();
    }

    bool equals(Object obj) {
        return _trie.equals(obj);
    }

    void clear() {
        _trie.clear();
    }

    bool put(string s, V v) {
        bool added = _trie.put(s, v);
        while (!added && _growby > 0) {
            ArrayTernaryTrie!(V) bigger = new ArrayTernaryTrie!V(_trie._key.length + _growby);
            foreach (string key, V value ; _trie)
                bigger.put(key, value);
            _trie = bigger;
            added = _trie.put(s, v);
        }

        return added;
    }

    V get(string s, int offset, int len) {
        return _trie.get(s, offset, len);
    }

    V get(ByteBuffer b, int offset, int len) {
        return _trie.get(b, offset, len);
    }

    V getBest(string s) {
        return _trie.getBest(s);
    }

    V getBest(string s, int offset, int length) {
        return _trie.getBest(s, offset, length);
    }

    V getBest(ByteBuffer b, int offset, int len) {
        return _trie.getBest(b, offset, len);
    }

    string toString() {
        return _trie.toString();
    }

    // Set!(string) keySet() {
    //     return _trie.keySet();
    // }

    bool isFull() {
        return false;
    }

    void dump() {
        _trie.dump();
    }

    bool isEmpty() {
        return _trie.isEmpty();
    }

    int size() {
        return _trie.size();
    }

}