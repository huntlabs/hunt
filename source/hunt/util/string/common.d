module hunt.util.string.common;

import hunt.container.Appendable;

import std.algorithm;
import std.array;
import std.exception;
import std.conv;
import std.string;
import std.uni;


class StringIndexOutOfBoundsException: Exception
{
    mixin basicExceptionCtors;
}


bool equalsIgnoreCase(string s1, string s2)
{
    return icmp(s1, s2) == 0;
}

bool equals(string s1, string s2)
{
    return s1 == s2;
}

/**
*/
class StringUtils
{
    private enum string FOLDER_SEPARATOR = "/";
    private enum string WINDOWS_FOLDER_SEPARATOR = "\\";
    private enum string TOP_PATH = "..";
    private enum string CURRENT_PATH = ".";
    private enum char EXTENSION_SEPARATOR = '.';

    enum string EMPTY = "";
    enum string[] EMPTY_STRING_ARRAY = [];

    enum char[] lowercases = ['\000', '\001', '\002', '\003', '\004', '\005', '\006', '\007', '\010',
            '\011', '\012', '\013', '\014', '\015', '\016', '\017', '\020', '\021', '\022', '\023', '\024', '\025',
            '\026', '\027', '\030', '\031', '\032', '\033', '\034', '\035', '\036', '\037', '\040', '\041', '\042',
            '\043', '\044', '\045', '\046', '\047', '\050', '\051', '\052', '\053', '\054', '\055', '\056', '\057',
            '\060', '\061', '\062', '\063', '\064', '\065', '\066', '\067', '\070', '\071', '\072', '\073', '\074',
            '\075', '\076', '\077', '\100', '\141', '\142', '\143', '\144', '\145', '\146', '\147', '\150', '\151',
            '\152', '\153', '\154', '\155', '\156', '\157', '\160', '\161', '\162', '\163', '\164', '\165', '\166',
            '\167', '\170', '\171', '\172', '\133', '\134', '\135', '\136', '\137', '\140', '\141', '\142', '\143',
            '\144', '\145', '\146', '\147', '\150', '\151', '\152', '\153', '\154', '\155', '\156', '\157', '\160',
            '\161', '\162', '\163', '\164', '\165', '\166', '\167', '\170', '\171', '\172', '\173', '\174', '\175',
            '\176', '\177'];

    enum string __ISO_8859_1 = "iso-8859-1";
    enum string __UTF8 = "utf-8";
    enum string __UTF16 = "utf-16";
    
    private enum string[string] CHARSETS = ["utf-8":__UTF8, "utf8":__UTF8, 
        "utf-16":__UTF16, "utf-8":__UTF16, 
        "iso-8859-1":__ISO_8859_1, "iso_8859_1":__ISO_8859_1];

    
    /**
     * Convert alternate charset names (eg utf8) to normalized name (eg UTF-8).
     *
     * @param s the charset to normalize
     * @return the normalized charset (or null if normalized version not found)
     */
    static string normalizeCharset(string s) {
        string n = CHARSETS.get(s, null);
        return (n == null) ? s : n;
    }

    /**
     * Convert alternate charset names (eg utf8) to normalized name (eg UTF-8).
     *
     * @param s      the charset to normalize
     * @param offset the offset in the charset
     * @param length the length of the charset in the input param
     * @return the normalized charset (or null if not found)
     */
    static string normalizeCharset(string s, int offset, int length) {
        return normalizeCharset(s[offset .. offset+length]);
    }

    static string asciiToLowerCase(string s)
    {
        return toLower(s);
    }

    static int toInt(string str, int from) {
        return to!int(str[from..$]);
    }

    static byte[] getBytes(string s) {
        return cast(byte[])s.dup;
    }

    static string[] split(string s, string c)
    {
        return s.splitter(c).map!(a => a.strip()).array;
    }

    static string[] split(string s, string c, int max)
    {
        string[] r = split(s, c);
        if(r.length>max)
            return r[0..max];
        else
         return r;
    }
}


string substring(string s, int beginIndex, int endIndex=-1)
{
    if(endIndex == -1)
        endIndex = cast(int)s.length;
    return s[beginIndex .. endIndex];
}

char charAt(string s, int i) nothrow
{
    return s[i];
}

bool contains(string[] items, string item)
{
    return items.canFind(item);
}



/**
*/
class StringBuilder : Appendable
{
    Appender!(byte[]) _buffer;

    this(size_t capacity=16)
    {
        _buffer.reserve(capacity);
    }

    
    // void append(in char[] s)
    // {
    //     _buffer.put(cast(string) s);
    // }

    void reset()
    {
        _buffer.clear();
    }

    StringBuilder append(char s)
    {
        _buffer.put(s);
        return this;
    }


    StringBuilder append(int i)
    {
        _buffer.put(cast(byte[])(to!(string)(i)));
        return this;
    }

    StringBuilder append(const(char)[] s)
    {
        _buffer.put(cast(byte[])s);
        return this;
    }

    StringBuilder append(const(char)[] s, int start, int end)
    {
        _buffer.put(cast(byte[])s[start..end]);
        return this;
    }

    // StringBuilder append(byte[] s, int start, int end)
    // {
    //     _buffer.put(s[start..end]);
    //     return this;
    // }

    /// Warning: It's different from the previous one.
    StringBuilder append(byte[] str, int offset, int len)
    {
        _buffer.put(str[offset..offset+len]);
        return this;
    }

    int length()
    {
        return cast(int)_buffer.data.length;
    }

    void setLength(int newLength) {
        _buffer.shrinkTo(newLength);
        // if (newLength < 0)
        //     throw new StringIndexOutOfBoundsException(to!string(newLength));
        // ensureCapacityInternal(newLength);

        // if (count < newLength) {
        //     Arrays.fill(value, count, newLength, '\0');
        // }

        // count = newLength;
    }

    private void ensureCapacityInternal(size_t minimumCapacity) {
        // overflow-conscious code
        // if (minimumCapacity > value.length) {
        //     value = Arrays.copyOf(value,
        //             newCapacity(minimumCapacity));
        // }
    }

    int lastIndexOf(string s)
    {
        string source = cast(string) _buffer.data;
        return cast(int)source.lastIndexOf(s);

        // return cast(int)_buffer.data.countUntil(cast(byte[])s);
    }

    override string toString()
    {
        return cast(string) _buffer.data.idup;
    }
}