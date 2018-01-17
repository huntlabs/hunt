module kiss.serialize;

import std.traits;
import std.string;
import core.stdc.string;

private:

// basic
// type -   size
//  0   -   1
//  1   -   2
//  2   -   4
//  3   -   8

// data

byte getbasictype(long size)
{
    if(size == 1)
        return 0;
    else if(size == 2)
        return 1;
    else if(size == 4)
        return 2;
    else if(size == 8)
        return 3;
    else 
        assert(0);
}

byte getbasicsize(byte type)
{
    if(type == 0)
        return 1;
    else if(type == 1)
        return 2;
    else if(type ==2)
        return 4;
    else if(type == 3)
        return 8;
    else
        assert(0);
}

byte[] serialize(T)(T t) if(isScalarType!T)
{
    byte[] data;
    data.length = T.sizeof + 1;
    data[0] = getbasictype(T.sizeof);
    memcpy(data.ptr + 1 , &t , T.sizeof);
    return data;
}

T unserialize(T )(const byte[] data , out long parse_index) if(isScalarType!T)
{
    assert( cast(byte)T.sizeof == getbasicsize(data[0]));
    
    T value;
    memcpy(&value , data.ptr + 1 , T.sizeof);
    
    parse_index = T.sizeof + 1;
    return value;
}

size_t getsize(T)(T t) if(isScalarType!T)
{
    return T.sizeof + 1;
}


// TString
// 1 type 4
// 2 len 
//  data

byte[] serialize(string str ) 
{
    byte[] data;
    ushort len = cast(ushort)str.length;
    data.length = 1 + 2 + len;
    data[0] = 4;
    memcpy(data.ptr + 1 , &len , 2);
    memcpy(data.ptr + 3 , str.toStringz() , len);
    return data;
}

string unserialize(T)(const byte[] data , out long parse_index) if(is(T == string))
{
    assert(data[0] == 4);
    uint len;
    memcpy(&len , data.ptr + 1 , 2);
    parse_index = 3 + len;
    return cast(T)(data[3 .. 3 + len].dup);
}

size_t getsize(string str ) 
{
    return 1 + 2 + str.length;
}

// TUnion
// 1 type 5
// 1 len 
//      data

byte[] serialize(T)(T t) if(is(T == union))
{
    byte[] data;
    data.length = T.sizeof + 2;
    data[0] = 5;
    data[1] = T.sizeof;
    memcpy(data.ptr + 2 , &t , T.sizeof);
    return data;
}

T unserialize(T)(const byte[] data , out long parse_index) if(is(T == union))
{
    assert(data[0] == 5);
    
    T value;
    byte len;
    memcpy(&len , data.ptr + 1 , 1);
    parse_index = 2 + len;
    memcpy(&value , data.ptr + 2 , len);
    return value;
}

size_t getsize(T)(T t) if(is(T == union))
{
    return 2 + T.sizeof;
}

string serializeMembers(T)()
{
    string str;
    foreach(m ; FieldNameTuple!T)
    {
        str ~= "data ~= serialize(t." ~ m ~");";
    }
    return str;
}

string unserializeMembers(T)()
{
    string str;

    str ~= "long index = 3; ";
    str ~= "long parse = 0; ";
    foreach(m ; FieldNameTuple!T)
    {
        str ~=" if ( index < parse_index)"; 
        str ~= "{";
        str ~= "t." ~ m ~ " = unserialize!(typeof(t." ~ m ~ "))(data[cast(uint)index .. data.length] , parse); ";
        str ~= "index += parse; }";
        
    }

    return str;
}

string getsizeMembers(T)()
{
    string str;
    foreach(m ; FieldNameTuple!T)
    {
        str ~= "total += getsize(t."  ~  m ~ ");";
    }
    return str;
}

// TSArray
// 1 type 8
// 2 size
// 4 length
// data
byte[] serialize(T)( T t) if(isStaticArray!T)
{
    byte[7] header;
    header[0] = 8;
    ushort uSize = cast(ushort)t.length;
    memcpy(header.ptr + 1 , &uSize , 2);
    byte[] data;
    for(size_t i = 0 ; i < uSize ; i++)
    {
        data ~= serialize(t[i]);
    }
    size_t len = data.length;
    memcpy(header.ptr + 3 , &len , 4);
    return header ~ data;
}

T unserialize(T)(const byte[] data , out long parse_index) if(isStaticArray!T)
{
    assert(data[0] == 8);
    T value;
    ushort uSize;
    uint len;
    memcpy(&uSize , data.ptr + 1 , 2);
    memcpy(&len , data.ptr + 3 , 4);
    parse_index = 7 + len;
    long index = 7;
    long parse = 0;
    for(size_t i = 0 ; i < uSize ; i++)
    {
        parse = 0;
        value[i] = unserialize!(typeof(value[0]))(data[index .. data.length] , parse);
        index += parse;
    }

    return value;
}

size_t getsize(T)( T t) if(isStaticArray!T)
{
    long total = 7;
    for(size_t i = 0 ; i < uSize ; i++)
    {
        total += getsize(t[i]);
    }

    return total;
}

public:

//  TDArray
// 1  type 9
// 2 size
// 4 length
// data
byte[] serialize(T)( T t) if(isDynamicArray!T && !is(T == string))
{
    byte[7] header;
    header[0] = 9;

    ushort uSize = cast(ushort)t.length;
    memcpy(header.ptr + 1 , &uSize , 2);
    byte[] data;
    for(size_t i = 0 ; i < uSize ; i++)
    {
        data ~= serialize(t[i]);
    }
    size_t len = data.length;
    memcpy(header.ptr + 3 , &len , 4);
    return header ~ data;
}

T unserialize(T)(const byte[] data )  if(isDynamicArray!T && !is(T == string))
{
    assert(data[0] == 9);     
    long parse_index;
    return unserialize!T(data , parse_index);
}

T unserialize(T)(const byte[] data , out long parse_index)  if(isDynamicArray!T && !is(T == string))
{
    assert(data[0] == 9);

    T value;
    ushort uSize;
    uint len;
    memcpy(&uSize , data.ptr + 1 , 2);
    memcpy(&len , data.ptr + 3 , 4);
    value.length = uSize;
    parse_index = 7 + len;
    uint index = 7;
    long parse = 0;
    for(size_t i = 0 ; i < uSize ; i++)
    {
        value[i] = unserialize!(typeof(value[0]))(data[index .. data.length] , parse);
        index += parse;
    }

    return value;
}

size_t getsize(T)( T t) if(isDynamicArray!T && !is(T == string))
{
    long total = 7;
    for(size_t i = 0 ; i < uSize ; i++)
    {
        total += serialize(t[i]);
    }
    return total;
}

// TStruct
// 1 type 6
// 2 len
// data
byte[] serialize(T)(T t) if(is(T == struct))
{
    byte[3] header;
    header[0] = 6;
    byte[]     data;

    mixin(serializeMembers!T());

    ushort len = cast(ushort)data.length;
    memcpy(header.ptr + 1 , &len , 2);
    return header ~ data;
}

T unserialize(T)(const byte[] data , out long parse_index) if(is(T == struct))
{
    assert(data[0] == 6);
    
    T t;
    ushort len;
    memcpy(&len , data.ptr + 1 , 2);
    parse_index = 3 + len;
    
    mixin(unserializeMembers!T());
    
    return t;
}

T unserialize(T)(const byte[] data ) if(is(T == struct))
{
    assert(data[0] == 6);

    long parse_index;

    return unserialize!T(data , parse_index);
}

size_t getsize(T)(T t) if(is(T == struct))
{
    long total;
    
    mixin(getsizeMembers!T());

    return cast(uint)total;
}

// TClass
// 1 type 7
// 2 len
//    data
byte[] serialize(T)(T t) if(is(T == class))
{
    byte[3] header;
    header[0] = 7;
    byte[]     data;
    
    mixin(serializeMembers!T());

    ushort len = cast(ushort)data.length;
    memcpy(header.ptr + 1 , &len , 2);
    return header ~ data;
}

T unserialize(T)(const byte[] data , out long parse_index)if(is(T == class))
{
    assert(data[0] == 7);

    T t = new T;
    ushort len;
    memcpy(&len , data.ptr + 1 , 2);
    parse_index = 3 + len;
    mixin(unserializeMembers!T());
    
    return t;
}

T unserialize(T)(const byte[] data )if(is(T == class))
{
    assert(data[0] == 7);
    
    long parse_index;
    
    return unserialize!T(data , parse_index);
}

size_t getsize(T)(T t) if(is(T == class))
{
    long total;
    
    mixin(getsizeMembers!T());
    
    return total;
}
