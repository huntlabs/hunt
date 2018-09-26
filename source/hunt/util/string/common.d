module hunt.util.string.common;


import std.ascii;
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


string substring(string s, int beginIndex, int endIndex=-1)
{
    if(endIndex == -1)
        endIndex = cast(int)s.length;
    return s[beginIndex .. endIndex];
}

string substring(string s, ulong beginIndex, ulong endIndex=-1)
{
    return substring(s,cast(int)beginIndex,cast(int)endIndex);
}

char charAt(string s, int i) nothrow
{
    return s[i];
}

char charAt(string s, ulong i) nothrow
{
    return s[i];
}

bool contains(string[] items, string item)
{
    return items.canFind(item);
}

 int compareTo(string value , string another)
 {  
        import std.algorithm.comparison;
        int len1 = cast(int)value.length;
        int len2 = cast(int)another.length;
        int lim = min(len1, len2);
        // char v1[] = value;
        // char v2[] = another.value;

        int k = 0;
        while (k < lim) {
            char c1 = value[k];
            char c2 = another[k];
            if (c1 != c2) {
                return c1 - c2;
            }
            k++;
        }
        return len1 - len2;
}
