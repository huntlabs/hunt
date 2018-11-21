module hunt.util.SearchPattern;

import hunt.lang.exception;

/**
 * SearchPattern
 * <p>
 * Fast search for patterns within strings and arrays of bytes.
 * Uses an implementation of the Boyer–Moore–Horspool algorithm
 * with a 256 character alphabet.
 * <p>
 * The algorithm has an average-case complexity of O(n)
 * on random text and O(nm) in the worst case.
 * where:
 * m = pattern length
 * n = length of data to search
 */
class SearchPattern {
    enum int alphabetSize = 256;
    private size_t[] table;
    private byte[] pattern;

    /**
     * Produces a SearchPattern instance which can be used
     * to find matches of the pattern in data
     *
     * @param pattern byte array containing the pattern
     * @return a new SearchPattern instance using the given pattern
     */
    static SearchPattern compile(byte[] pattern) {
        return new SearchPattern(pattern);
    }

    /**
     * Produces a SearchPattern instance which can be used
     * to find matches of the pattern in data
     *
     * @param pattern string containing the pattern
     * @return a new SearchPattern instance using the given pattern
     */
    static SearchPattern compile(string pattern) {
        return new SearchPattern(cast(byte[])pattern);
    }

    /**
     * @param pattern byte array containing the pattern used for matching
     */
    private this(byte[] pattern) {
        this.pattern = pattern;

        if (pattern.length == 0)
            throw new IllegalArgumentException("Empty Pattern");

        //Build up the pre-processed table for this pattern.
        table = new size_t[alphabetSize];
        for (size_t i = 0; i < table.length; ++i)
            table[i] = pattern.length;
        for (size_t i = 0; i < pattern.length - 1; ++i)
            table[0xff & pattern[i]] = pattern.length - 1 - i;
    }


    /**
     * Search for a complete match of the pattern within the data
     *
     * @param data   The data in which to search for. The data may be arbitrary binary data,
     *               but the pattern will always be {@link StandardCharsets#US_ASCII} encoded.
     * @param offset The offset within the data to start the search
     * @param length The length of the data to search
     * @return The index within the data array at which the first instance of the pattern or -1 if not found
     */
    int match(byte[] data, int offset, int length) {
        validate(data, offset, length);
        int skip = offset;
        int len = cast(int)pattern.length;
        while (skip <= offset + length - len) {
            for (size_t i = len - 1; data[skip + i] == pattern[i]; i--) {
                if (i == 0) return skip;
            }

            skip += table[0xff & data[skip + len - 1]];
        }

        return -1;
    }

    /**
     * Search for a partial match of the pattern at the end of the data.
     *
     * @param data   The data in which to search for. The data may be arbitrary binary data,
     *               but the pattern will always be {@link StandardCharsets#US_ASCII} encoded.
     * @param offset The offset within the data to start the search
     * @param length The length of the data to search
     * @return the length of the partial pattern matched and 0 for no match.
     */
    int endsWith(byte[] data, int offset, int length) {
        validate(data, offset, length);

        int len = cast(int)pattern.length;
        int skip = (len <= length) ? (offset + length - len) : offset;
        while (skip < offset + length) {
            for (size_t i = (offset + length - 1) - skip; data[skip + i] == pattern[i]; --i)
                if (i == 0) return cast(int) (offset + length - skip);

            if (skip + len - 1 < data.length)
                skip += table[0xff & data[skip + len - 1]];
            else
                skip++;
        }

        return 0;
    }

    /**
     * Search for a possibly partial match of the pattern at the start of the data.
     *
     * @param data    The data in which to search for. The data may be arbitrary binary data,
     *                but the pattern will always be {@link StandardCharsets#US_ASCII} encoded.
     * @param offset  The offset within the data to start the search
     * @param length  The length of the data to search
     * @param matched The length of the partial pattern already matched
     * @return the length of the partial pattern matched and 0 for no match.
     */
    int startsWith(byte[] data, int offset, int length, int matched) {
        validate(data, offset, length);

        int matchedCount = 0;

        for (size_t i = 0; i < cast(int)pattern.length - matched && i < length; i++) {
            if (data[offset + i] == pattern[i + matched])
                matchedCount++;
            else
                return 0;
        }

        return matched + matchedCount;
    }

    /**
     * Performs legality checks for standard arguments input into SearchPattern methods.
     *
     * @param data   The data in which to search for. The data may be arbitrary binary data,
     *               but the pattern will always be {@link StandardCharsets#US_ASCII} encoded.
     * @param offset The offset within the data to start the search
     * @param length The length of the data to search
     */
    private void validate(byte[] data, int offset, int length) {
        if (offset < 0)
            throw new IllegalArgumentException("offset was negative");
        else if (length < 0)
            throw new IllegalArgumentException("length was negative");
        else if (offset + length > data.length)
            throw new IllegalArgumentException("(offset+length) out of bounds of data[]");
    }

    /**
     * @return The length of the pattern in bytes.
     */
    int getLength() {
        return cast(int)pattern.length;
    }
}
