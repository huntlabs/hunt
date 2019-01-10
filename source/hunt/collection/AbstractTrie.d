module hunt.collection.AbstractTrie;

import hunt.collection.ByteBuffer;
import hunt.collection.Set;
import hunt.collection.Trie;

import hunt.Exceptions;
import std.conv;

abstract class AbstractTrie(V) : Trie!(V) {
    private bool _caseInsensitive;

    protected this(bool insensitive) {
        _caseInsensitive = insensitive;
    }

    bool put(string s, V v) {
        implementationMissing(false);
        return false;
    }
    
    bool put(V v) {
        return put(v.to!string(), v);
    }

    
    V remove(string s) {
        V o = get(s);
        put(s, V.init);
        return o;
    }

    
    V get(string s) {
        return get(s, 0, cast(int)s.length);
    }

    V get(string s, int offset, int len) {
        implementationMissing(false);
        return V.init;
    }
    
    V get(ByteBuffer b) {
        return get(b, 0, b.remaining());
    }

    V get(ByteBuffer b, int offset, int len) {
        implementationMissing(false);
        return V.init;
    }
    
    V getBest(string s) {
        return getBest(s, 0, cast(int)s.length);
    }

    V getBest(string s, int offset, int len) {
        implementationMissing(false);
        return V.init;
    }
    
    V getBest(byte[] b, int offset, int len) {
        return getBest(cast(string)(b[offset .. offset + len]));
    }

    V getBest(ByteBuffer b, int offset, int len) {
        implementationMissing(false);
        return V.init;
    }

    Set!string keySet() {
        implementationMissing(false);
        return null;
    }

    bool isFull() {        
        implementationMissing(false);
        return false;
    }
    
    bool isCaseInsensitive() {
        return _caseInsensitive;
    }

    void clear() {
        implementationMissing(false);
    }
}
