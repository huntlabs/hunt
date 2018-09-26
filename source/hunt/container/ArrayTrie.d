module hunt.container.ArrayTrie;

import hunt.container.AbstractTrie;
import hunt.container.Appendable;
import hunt.container.ByteBuffer;
import hunt.container.HashSet;
import hunt.container.Set;
import hunt.container.Trie;

import hunt.util.exception;
import hunt.util.string.StringBuilder;

import hunt.logging;
import std.conv;

/**
 * <p>A Trie string lookup data structure using a fixed size array.</p>
 * <p>This implementation is always case insensitive and is optimal for
 * a small number of fixed strings with few special characters.  The
 * Trie is stored in an array of lookup tables, each indexed by the
 * next character of the key.   Frequently used characters are directly
 * indexed in each lookup table, whilst infrequently used characters
 * must use a big character table.
 * </p>
 * <p>This Trie is very space efficient if the key characters are
 * from ' ', '+', '-', ':', ';', '.', 'A' to 'Z' or 'a' to 'z'.
 * Other ISO-8859-1 characters can be used by the key, but less space
 * efficiently.
 * </p>
 * <p>This Trie is not Threadsafe and contains no mutual exclusion
 * or deliberate memory barriers.  It is intended for an ArrayTrie to be
 * built by a single thread and then used concurrently by multiple threads
 * and not mutated during that access.  If concurrent mutations of the
 * Trie is required external locks need to be applied.
 * </p>
 *
 * @param !(V) the element of entry
 */
class ArrayTrie(V) : AbstractTrie!(V) {
    /**
     * The Size of a Trie row is how many characters can be looked
     * up directly without going to a big index.  This is set at
     * 32 to cover case insensitive alphabet and a few other common
     * characters.
     */
    private enum int ROW_SIZE = 32;

    /**
     * The index lookup table, this maps a character as a byte
     * (ISO-8859-1 or UTF8) to an index within a Trie row
     */
    private enum int[] __lookup =
    [ // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
   /*0*/-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
   /*1*/-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
   /*2*/31, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 26, -1, 27, 30, -1,
   /*3*/-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 28, 29, -1, -1, -1, -1,
   /*4*/-1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
   /*5*/15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1,
   /*6*/-1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
   /*7*/15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1,
    ];

    /**
     * The Trie rows in a single array which allows a lookup of row,character
     * to the next row in the Trie.  This is actually a 2 dimensional
     * array that has been flattened to achieve locality of reference.
     * The first ROW_SIZE entries are for row 0, then next ROW_SIZE
     * entries are for row 1 etc.   So in general instead of using
     * _rows[row][index], we use _rows[row*ROW_SIZE+index] to look up
     * the next row for a given character.
     * <p>
     * The array is of characters rather than integers to save space.
     */
    private byte[] _rowIndex;

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
     * A big index for each row.
     * If a character outside of the lookup map is needed,
     * then a big index will be created for the row, with
     * 256 entries, one for each possible byte.
     */
    private byte[][] _bigIndex;

    /**
     * The number of rows allocated
     */
    private byte _rows;

    this() {
        this(128);
    }

    /* ------------------------------------------------------------ */

    /**
     * @param capacity The capacity of the trie, which at the worst case
     *                 is the total number of characters of all keys stored in the Trie.
     *                 The capacity needed is dependent of the shared prefixes of the keys.
     *                 For example, a capacity of 6 nodes is required to store keys "foo"
     *                 and "bar", but a capacity of only 4 is required to
     *                 store "bar" and "bat".
     */
    this(int capacity) {
        super(true);
        _value = new V[capacity];
        _rowIndex = new byte[capacity * 32];
        _key = new string[capacity];
    }

    /* ------------------------------------------------------------ */
    override
    void clear() {
        _rows = 0;
        _value[] = V.init;
        _rowIndex[] = 0;
        _key[] = null;
    }

    /* ------------------------------------------------------------ */
    override
    bool put(string s, V v) {
        int t = 0;
        size_t k;
        size_t limit = s.length;
        for (k = 0; k < limit; k++) {
            byte c = s[k];

            int index = __lookup[c & 0x7f];
            if (index >= 0) {
                int idx = t * ROW_SIZE + index;
                t = _rowIndex[idx];
                if (t == 0) {
                    if (++_rows >= _value.length)
                        return false;
                    t = _rowIndex[idx] = _rows;
                }
            } else if (c > 127)
                throw new IllegalArgumentException("non ascii character");
            else {
                if (_bigIndex is null)
                    _bigIndex = new byte[][_value.length];
                if (t >= _bigIndex.length)
                    return false;
                byte[] big = _bigIndex[t];
                if (big is null)
                    big = _bigIndex[t] = new byte[128];
                t = big[c];
                if (t == 0) {
                    if (_rows == _value.length)
                        return false;
                    t = big[c] = ++_rows;
                }
            }
        }

        if (t >= _key.length) {
            _rows = cast(byte) _key.length;
            return false;
        }

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
        for (int i = 0; i < len; i++) {
            byte c = s[offset + i];
            int index = __lookup[c & 0x7f];
            if (index >= 0) {
                int idx = t * ROW_SIZE + index;
                t = _rowIndex[idx];
                if (t == 0)
                    return V.init;
            } else {
                byte[] big = _bigIndex is null ? null : _bigIndex[t];
                if (big is null)
                    return V.init;
                t = big[c];
                if (t == 0)
                    return V.init;
            }
        }
        return _value[t];
    }

    /* ------------------------------------------------------------ */
    override
    V get(ByteBuffer b, int offset, int len) {
        int t = 0;
        for (int i = 0; i < len; i++) {
            byte c = b.get(offset + i);
            int index = __lookup[c & 0x7f];
            if (index >= 0) {
                int idx = t * ROW_SIZE + index;
                t = _rowIndex[idx];
                if (t == 0)
                    return V.init;
            } else {
                byte[] big = _bigIndex is null ? null : _bigIndex[t];
                if (big is null)
                    return V.init;
                t = big[c];
                if (t == 0)
                    return V.init;
            }
        }
        return _value[t];
    }

    /* ------------------------------------------------------------ */
    override
    V getBest(byte[] b, int offset, int len) {
        return getBest(0, b, offset, len);
    }

    /* ------------------------------------------------------------ */
    override
    V getBest(ByteBuffer b, int offset, int len) {
        if (b.hasArray())
            return getBest(0, b.array(), b.arrayOffset() + b.position() + offset, len);
        return getBest(0, b, offset, len);
    }

    /* ------------------------------------------------------------ */
    override
    V getBest(string s, int offset, int len) {
        return getBest(0, s, offset, len);
    }

    /* ------------------------------------------------------------ */
    private V getBest(int t, string s, int offset, int len) {
        int pos = offset;
        for (int i = 0; i < len; i++) {
            byte c = s[pos++];
            int index = __lookup[c & 0x7f];
            if (index >= 0) {
                int idx = t * ROW_SIZE + index;
                int nt = _rowIndex[idx];
                if (nt == 0)
                    break;
                t = nt;
            } else {
                byte[] big = _bigIndex is null ? null : _bigIndex[t];
                if (big is null)
                    return V.init;
                int nt = big[c];
                if (nt == 0)
                    break;
                t = nt;
            }

            // Is the next Trie is a match
            if (_key[t] !is null) {
                // Recurse so we can remember this possibility
                V best = getBest(t, s, offset + i + 1, len - i - 1);
                
                static if(is(V == class)) {
                    if (best !is null)
                        return best;
                } else {
                    if (best != V.init)
                        return best;
                }

                return _value[t];
            }
        }
        return _value[t];
    }

    /* ------------------------------------------------------------ */
    private V getBest(int t, byte[] b, int offset, int len) {
        for (int i = 0; i < len; i++) {
            byte c = b[offset + i];
            int index = __lookup[c & 0x7f];
            if (index >= 0) {
                int idx = t * ROW_SIZE + index;
                int nt = _rowIndex[idx];
                if (nt == 0)
                    break;
                t = nt;
            } else {
                byte[] big = _bigIndex is null ? null : _bigIndex[t];
                if (big is null)
                    return V.init;
                int nt = big[c];
                if (nt == 0)
                    break;
                t = nt;
            }

            // Is the next Trie is a match
            if (_key[t] !is null) {
                // Recurse so we can remember this possibility
                V best = getBest(t, b, offset + i + 1, len - i - 1);
                static if(is(V == class)) {
                    if (best !is null)
                        return best;
                } else {
                    if (best != V.init)
                        return best;
                }

                break;
            }
        }
        return _value[t];
    }

    private V getBest(int t, ByteBuffer b, int offset, int len) {
        int pos = b.position() + offset;
        for (int i = 0; i < len; i++) {
            byte c = b.get(pos++);
            int index = __lookup[c & 0x7f];
            if (index >= 0) {
                int idx = t * ROW_SIZE + index;
                int nt = _rowIndex[idx];
                if (nt == 0)
                    break;
                t = nt;
            } else {
                byte[] big = _bigIndex is null ? null : _bigIndex[t];
                if (big is null)
                    return V.init;
                int nt = big[c];
                if (nt == 0)
                    break;
                t = nt;
            }

            // Is the next Trie is a match
            if (_key[t] !is null) {
                // Recurse so we can remember this possibility
                V best = getBest(t, b, offset + i + 1, len - i - 1);
                
                static if(is(V == class)) {
                    if (best !is null)
                        return best;
                } else {
                    if (best != V.init)
                        return best;
                }

                break;
            }
        }
        return _value[t];
    }


    override
    string toString() {
        StringBuilder buf = new StringBuilder();
        toString(buf, 0);

        if (buf.length() == 0)
            return "{}";

        buf.setCharAt(0, '{');
        buf.append('}');
        return buf.toString();
    }


    private void toString(Appendable ot, int t) {
        void doAppend() {
            try {
                ot.append(',');
                ot.append(_key[t]);
                ot.append('=');
                ot.append(_value[t].to!string());
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }

        static if(is(V == class)) {
            if (_value[t] !is null)
                doAppend();
        } else {
            if (_value[t] != V.init)
                doAppend();
        }

        for (int i = 0; i < ROW_SIZE; i++) {
            int idx = t * ROW_SIZE + i;
            if (_rowIndex[idx] != 0)
                toString(ot, _rowIndex[idx]);
        }

        byte[] big = _bigIndex is null ? null : _bigIndex[t];
        if (big !is null) {
            foreach (int i ; big)
                if (i != 0)
                    toString(ot, i);
        }

    }

    override
    Set!(string) keySet() {
        Set!(string) keys = new HashSet!(string)();
        keySet(keys, 0);
        return keys;
    }

    private void keySet(Set!(string) set, int t) {
        static if(is(V == class)) {
            if (t < _value.length && _value[t] !is null)
                set.add(_key[t]);
        } else {
            if (t < _value.length && _value[t] != V.init)
                set.add(_key[t]);
        }

        for (int i = 0; i < ROW_SIZE; i++) {
            int idx = t * ROW_SIZE + i;
            if (idx < _rowIndex.length && _rowIndex[idx] != 0)
                keySet(set, _rowIndex[idx]);
        }

        byte[] big = _bigIndex is null || t >= _bigIndex.length ? null : _bigIndex[t];
        // if (big !is null) {
            foreach (int i ; big)
                if (i != 0)
                    keySet(set, i);
        // }
    }

    override
    bool isFull() {
        return _rows + 1 >= _key.length;
    }
}
