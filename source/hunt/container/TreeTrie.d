module hunt.container.TreeTrie;

import hunt.container.AbstractTrie;
import hunt.container.Appendable;
import hunt.container.ArrayList;
import hunt.container.ByteBuffer;
import hunt.container.HashSet;
import hunt.container.List;
import hunt.container.Set;

import hunt.util.exception;
import hunt.string;

import std.conv;

/* ------------------------------------------------------------ */

/**
 * A Trie string lookup data structure using a tree
 * <p>
 * This implementation is always case insensitive and is optimal for a variable
 * number of fixed strings with few special characters.
 * </p>
 * <p>
 * This Trie is stored in a Tree and is unlimited in capacity
 * </p>
 * <p>
 * <p>
 * This Trie is not Threadsafe and contains no mutual exclusion or deliberate
 * memory barriers. It is intended for an ArrayTrie to be built by a single
 * thread and then used concurrently by multiple threads and not mutated during
 * that access. If concurrent mutations of the Trie is required external locks
 * need to be applied.
 * </p>
 *
 * @param (V) the entry type
 */
class TreeTrie(V) : AbstractTrie!(V) {
    private enum int[] __lookup =
    [// 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
   /*0*/-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
   /*1*/-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
   /*2*/31, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 26, -1, 27, 30, -1,
   /*3*/-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 28, 29, -1, -1, -1, -1,
   /*4*/-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
   /*5*/15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1,
   /*6*/-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
   /*7*/15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1,
    ];
    private enum int INDEX = 32;
    private TreeTrie!(V)[] _nextIndex;
    private List!(TreeTrie!(V)) _nextOther;
    private char _c;
    private string _key;
    private V _value;

    this() {
        this('\0');
    }

    private this(char c) {
        _nextOther = new ArrayList!(TreeTrie!(V))();
        _nextIndex = new TreeTrie[INDEX];
        super(true);
        this._c = c;
    }

    override
    void clear() {
        _nextIndex[] = null;
        _nextOther.clear();
        _key = null;
        _value = V.init;
    }

    override
    bool put(string s, V v) {
        TreeTrie!(V) t = this;
        size_t limit = s.length;
        for (size_t k = 0; k < limit; k++) {
            byte c = s[k];

            int index = c >= 0 && c < 0x7f ? __lookup[c] : -1;
            if (index >= 0) {
                if (t._nextIndex[index] is null)
                    t._nextIndex[index] = new TreeTrie!(V)(c);
                t = t._nextIndex[index];
            } else {
                TreeTrie!(V) n = null;
                for (int i = t._nextOther.size(); i-- > 0; ) {
                    n = t._nextOther.get(i);
                    if (n._c == c)
                        break;
                    n = null;
                }
                if (n is null) {
                    n = new TreeTrie!(V)(c);
                    t._nextOther.add(n);
                }
                t = n;
            }
        }
        static if(is(V == class)) {
            t._key = v is null ? null : s;
        } else {
            t._key = v == V.init ? null : s;
        }
        
        t._value = v;
        return true;
    }

    override
    V get(string s, int offset, int len) {
        TreeTrie!(V) t = this;
        for (int i = 0; i < len; i++) {
            byte c = s.charAt(offset + i);
            int index = c >= 0 && c < 0x7f ? __lookup[c] : -1;
            if (index >= 0) {
                if (t._nextIndex[index] is null)
                    return V.init;
                t = t._nextIndex[index];
            } else {
                TreeTrie!(V) n = null;
                for (int j = t._nextOther.size(); j-- > 0; ) {
                    n = t._nextOther.get(j);
                    if (n._c == c)
                        break;
                    n = null;
                }
                if (n is null)
                    return V.init;
                t = n;
            }
        }
        return t._value;
    }

    override
    V get(ByteBuffer b, int offset, int len) {
        TreeTrie!(V) t = this;
        for (int i = 0; i < len; i++) {
            byte c = b.get(offset + i);
            int index = c >= 0 && c < 0x7f ? __lookup[c] : -1;
            if (index >= 0) {
                if (t._nextIndex[index] is null)
                    return V.init;
                t = t._nextIndex[index];
            } else {
                TreeTrie!(V) n = null;
                for (int j = t._nextOther.size(); j-- > 0; ) {
                    n = t._nextOther.get(j);
                    if (n._c == c)
                        break;
                    n = null;
                }
                if (n is null)
                    return V.init;
                t = n;
            }
        }
        return t._value;
    }

    override
    V getBest(byte[] b, int offset, int len) {
        TreeTrie!(V) t = this;
        for (int i = 0; i < len; i++) {
            byte c = b[offset + i];
            int index = c >= 0 && c < 0x7f ? __lookup[c] : -1;
            if (index >= 0) {
                if (t._nextIndex[index] is null)
                    break;
                t = t._nextIndex[index];
            } else {
                TreeTrie!(V) n = null;
                for (int j = t._nextOther.size(); j-- > 0; ) {
                    n = t._nextOther.get(j);
                    if (n._c == c)
                        break;
                    n = null;
                }
                if (n is null)
                    break;
                t = n;
            }

            // Is the next Trie is a match
            if (t._key !is null) {
                // Recurse so we can remember this possibility
                V best = t.getBest(b, offset + i + 1, len - i - 1);
                
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
        return t._value;
    }

    override
    V getBest(string s, int offset, int len) {
        TreeTrie!(V) t = this;
        for (int i = 0; i < len; i++) {
            byte c = cast(byte) (0xff & s[offset + i]);
            int index = c >= 0 && c < 0x7f ? __lookup[c] : -1;
            if (index >= 0) {
                if (t._nextIndex[index] is null)
                    break;
                t = t._nextIndex[index];
            } else {
                TreeTrie!(V) n = null;
                for (int j = t._nextOther.size(); j-- > 0; ) {
                    n = t._nextOther.get(j);
                    if (n._c == c)
                        break;
                    n = null;
                }
                if (n is null)
                    break;
                t = n;
            }

            // Is the next Trie is a match
            if (t._key !is null) {
                // Recurse so we can remember this possibility
                V best = t.getBest(s, offset + i + 1, len - i - 1);
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
        return t._value;
    }

    override
    V getBest(ByteBuffer b, int offset, int len) {
        if (b.hasArray())
            return getBest(b.array(), b.arrayOffset() + b.position() + offset, len);
        return getBestByteBuffer(b, offset, len);
    }

    private V getBestByteBuffer(ByteBuffer b, int offset, int len) {
        TreeTrie!(V) t = this;
        int pos = b.position() + offset;
        for (int i = 0; i < len; i++) {
            byte c = b.get(pos++);
            int index = c >= 0 && c < 0x7f ? __lookup[c] : -1;
            if (index >= 0) {
                if (t._nextIndex[index] is null)
                    break;
                t = t._nextIndex[index];
            } else {
                TreeTrie!(V) n = null;
                for (int j = t._nextOther.size(); j-- > 0; ) {
                    n = t._nextOther.get(j);
                    if (n._c == c)
                        break;
                    n = null;
                }
                if (n is null)
                    break;
                t = n;
            }

            // Is the next Trie is a match
            if (t._key !is null) {
                // Recurse so we can remember this possibility
                V best = t.getBest(b, offset + i + 1, len - i - 1);

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
        return t._value;
    }


    override
    string toString() {
        StringBuilder buf = new StringBuilder();
        toString(buf, this);

        if (buf.length == 0)
            return "{}";

        buf.setCharAt(0, '{');
        buf.append('}');
        return buf.toString();
    }

    private static void toString(V)(Appendable ot, TreeTrie!(V) t) {
        if (t is null) 
            return;

        void doAppend() {
            try {
                ot.append(',');
                ot.append(t._key);
                ot.append('=');
                ot.append(t._value.to!string());
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }

        static if(is(V == class)) {
            if (t._value !is null)
                doAppend();
        } else {
            if (t._value != V.init)
                doAppend();
        }

        for (int i = 0; i < INDEX; i++) {
            if (t._nextIndex[i] !is null)
                toString(ot, t._nextIndex[i]);
        }
        for (int i = t._nextOther.size(); i-- > 0; )
            toString(ot, t._nextOther.get(i));
    }

    override
    Set!(string) keySet() {
        Set!(string) keys = new HashSet!string();
        keySet(keys, this);
        return keys;
    }

    private static void keySet(V)(Set!(string) set, TreeTrie!(V) t) {
        if (t !is null) {
            if (t._key !is null)
                set.add(t._key);

            for (int i = 0; i < INDEX; i++) {
                if (t._nextIndex[i] !is null)
                    keySet(set, t._nextIndex[i]);
            }
            for (int i = t._nextOther.size(); i-- > 0; )
                keySet(set, t._nextOther.get(i));
        }
    }

    override
    bool isFull() {
        return false;
    }

}
