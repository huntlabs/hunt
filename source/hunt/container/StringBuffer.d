module hunt.container.StringBuffer;

import hunt.container.Appendable;

import std.array;
import std.conv;

/**
*/
class StringBuffer : Appendable
{
    Appender!string _buffer;
    // private int len;

    this(size_t capacity = 16){

    }

    void setLength(int len)
    {
        if(len == 0)
        {
            _buffer = Appender!(string).init;
        }
        else
        {
            string tmp = _buffer.data[0..len];

            _buffer = Appender!(string).init;
            _buffer.put(tmp);
        }

        // this.len = len;
    }

    void clear()
    {
        _buffer = Appender!(string).init;
    }

    int length()
    {
        return cast(int)_buffer.data.length;
        // return len;
    }

    Appendable append(const(char)[] csq)
    {
        _buffer.put(csq);
        // len += cast(int) csq.length;
        return this;
    }


    Appendable append(const(char)[] csq, int start, int end)
    {
        _buffer.put(csq[start..end]);
        // len += end - start;
        return this;
    }


    Appendable append(char c) 
    {
        _buffer.put(c);
        // len++;
        return this;
    }

    Appendable append(int c) 
    {
        string s = to!string(c);
        _buffer.put(s);
        // len += cast(int)s.length;
        return this;
    }

    Appendable append(float c) 
    {
        string s = to!string(c);
        _buffer.put(s);
        // len += cast(int)s.length;
        return this;
    }

    override string toString()
    {
        // return _buffer.data[0..len];
        return _buffer.data;
    }

}