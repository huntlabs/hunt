module hunt.container.Trie;

import hunt.container.ByteBuffer;
import hunt.container.Set;

/* ------------------------------------------------------------ */

/**
 * A Trie string lookup data structure.
 *
 * @param (V) the Trie entry type
 */
interface Trie(V) {
    /* ------------------------------------------------------------ */

    /**
     * Put an entry into the Trie
     *
     * @param s The key for the entry
     * @param v The value of the entry
     * @return True if the Trie had capacity to add the field.
     */
    bool put(string s, V v);

    /* ------------------------------------------------------------ */

    /**
     * Put a value as both a key and a value.
     *
     * @param v The value and key
     * @return True if the Trie had capacity to add the field.
     */
    bool put(V v);

    /* ------------------------------------------------------------ */
    V remove(string s);

    /* ------------------------------------------------------------ */

    /**
     * Get an exact match from a string key
     *
     * @param s The key
     * @return the value for the string key
     */
    
    V get(string s);
    /* ------------------------------------------------------------ */

    /**
     * Get an exact match from a string key
     *
     * @param s      The key
     * @param offset The offset within the string of the key
     * @param len    the length of the key
     * @return the value for the string / offset / length
     */
    V get(string s, int offset, int len);

    /* ------------------------------------------------------------ */

    /**
     * Get an exact match from a segment of a ByteBuufer as key
     *
     * @param b The buffer
     * @return The value or null if not found
     */
    V get(ByteBuffer b);

    /* ------------------------------------------------------------ */

    /**
     * Get an exact match from a segment of a ByteBuufer as key
     *
     * @param b      The buffer
     * @param offset The offset within the buffer of the key
     * @param len    the length of the key
     * @return The value or null if not found
     */
    V get(ByteBuffer b, int offset, int len);

    /* ------------------------------------------------------------ */

    /**
     * Get the best match from key in a string.
     *
     * @param s The string
     * @return The value or null if not found
     */
    V getBest(string s);

    /* ------------------------------------------------------------ */

    /**
     * Get the best match from key in a string.
     *
     * @param s      The string
     * @param offset The offset within the string of the key
     * @param len    the length of the key
     * @return The value or null if not found
     */
    V getBest(string s, int offset, int len);

    /* ------------------------------------------------------------ */

    /**
     * Get the best match from key in a byte array.
     * The key is assumed to by ISO_8859_1 characters.
     *
     * @param b      The buffer
     * @param offset The offset within the array of the key
     * @param len    the length of the key
     * @return The value or null if not found
     */
    V getBest(byte[] b, int offset, int len);

    /* ------------------------------------------------------------ */

    /**
     * Get the best match from key in a byte buffer.
     * The key is assumed to by ISO_8859_1 characters.
     *
     * @param b      The buffer
     * @param offset The offset within the buffer of the key
     * @param len    the length of the key
     * @return The value or null if not found
     */
    V getBest(ByteBuffer b, int offset, int len);

    /* ------------------------------------------------------------ */
    Set!string keySet();

    /* ------------------------------------------------------------ */
    bool isFull();

    /* ------------------------------------------------------------ */
    bool isCaseInsensitive();

    /* ------------------------------------------------------------ */
    void clear();

}
