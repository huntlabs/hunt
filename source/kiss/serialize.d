module kiss.serialize;


import std.traits;
import std.string;
import core.stdc.string;
import std.stdio;
import std.bitmanip;
import std.math;

private:



enum bool isType(T1 , T2) = is(T1 == T2) || is(T1 == ImmutableOf!T2) || is(T1 == ConstOf!T2) || is(T1 == InoutOf!T2) || is(T1 == SharedOf!T2 ) || is(T1 == SharedConstOf!T2) || is(T1 == SharedInoutOf!T2);

enum bool isSignedType(T) = isType!(T , byte) || isType!(T , short) || isType!(T , int) || isType!(T , long);
enum bool isUnsignedType(T) = isType!(T , ubyte) ||  isType!(T , ushort) || isType!(T , uint) || isType!(T , ulong);
enum bool isBigSignedType(T) = isType!(T , int) || isType!(T, long);
enum bool isBigUnsignedType(T) = isType!(T , uint) || isType!(T , ulong);



//unsigned
ulong[] byte_dots = [ 1 << 7,
	1 << 14,
	1 << 21,
	1 << 28,
	cast(ulong)1 << 35,
	cast(ulong)1 << 42,
	cast(ulong)1 << 49,
	cast(ulong)1 << 56,
	cast(ulong)1 << 63,
];

//signed
ulong[] byte_dots_s = [ 1 << 6,
	1 << 13,
	1 << 20,
	1 << 27,
	cast(ulong)1 << 34,
	cast(ulong)1 << 41,
	cast(ulong)1 << 48,
	cast(ulong)1 << 55,
	cast(ulong)1 << 62,
];

ubyte getbytenum(ulong v)
{
	ubyte i = 0;
	for( ; i < byte_dots.length ; i++)
	{
		if( v <= byte_dots[i])
		{
			break;
		}
	}
	return cast(ubyte)(i + 1);
}

ubyte getbytenums(ulong v)
{
	ubyte i = 0;
	for( ; i < byte_dots_s.length ; i++)
	{
		if( v <= byte_dots_s[i])
		{
			break;
		}
	}
	
	
	return cast(ubyte)(i + 1);
}



//signed
byte[] toVariant(T)(T t) if (isSignedType!T)
{
	bool symbol = false;
	if( t < 0)
		symbol = true;
	ubyte multiple = 1;
	
	ulong val = cast(ulong)abs(t);

	ubyte num = getbytenums(val);
	ubyte[] var;
	for(size_t i = num  ; i > 1 ; i--)
	{
		auto n = val / (byte_dots_s[i - 2] * multiple);
		if(symbol && multiple == 1)
			n = n | 0x40;
		var ~= cast(ubyte)n;
		val = (val % (byte_dots_s[i - 2] * multiple));
		multiple = 2;
	}
	
	if( num == 1 && symbol)
		val = val | 0x40;
	
	var ~= cast(ubyte)(val | 0x80);
	
	return cast(byte[])var;
}

T	toT(T)(const byte[] b , out long index) if(isSignedType!T)
{
	T val = 0;
	ubyte i = 0;	
	bool symbol = false;
	for(i = 0 ; i < b.length ; i++)
	{
		if( i == 0)
		{
			val = (b[i] & 0x3F);
			if( b[i] & 0x40)
				symbol = true;
		}
		else if( i == 1)
		{
			val = cast(T)((val << 6) + (b[i] & 0x7F));
		}
		else
		{	
			val = cast(T)((val << 7) + (b[i] & 0x7F));
		}
		
		if(b[i] & 0x80)
			break;
	}
	index = i + 1;
	
	if(symbol)
		return cast(T)(val * -1);
	else
		return val;
}



//unsigned
byte[] toVariant(T)(T t) if(isUnsignedType!T) 
{
	ubyte num = getbytenum(cast(ulong)t);
	T val = t;
	ubyte[] var;
	for(size_t i = num  ; i > 1 ; i--)
	{
		auto n = val / (byte_dots[i - 2]);
		var ~= cast(ubyte)n;
		val = val % (byte_dots[i - 2]);
	}
	var ~= cast(ubyte)(val | 0x80);
	return cast(byte[])var;
}

//unsigned
T	toT(T)(const byte[] b , out long index) if(isUnsignedType!T)
{
	T val = 0;
	ubyte i = 0;	
	for(i = 0 ; i < b.length ; i++)
	{
		
		val = cast(T)((val << 7) + (b[i] & 0x7F));
		if(b[i] & 0x80)
			break;
	}
	index = i + 1;
	return val;
}











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



public:

///////////////////////////////////////////////////////////
// basic
// type 		  size
//  0     - 		1
//  1	 -			2
//  2	 -			4
//  3	 - 			8
//	data
///////////////////////////////////////////////////////////
///
byte[] serialize(T)(T t) if(isScalarType!T && ! isBigSignedType!T && ! isBigUnsignedType!T)
{
	byte[] data;
	data.length = T.sizeof + 1;
	data[0] = getbasictype(T.sizeof);
	memcpy(data.ptr + 1 , &t , T.sizeof);
	return data;
}


T unserialize(T )(const byte[] data ) if(isScalarType!T && !isBigSignedType!T && !isBigUnsignedType!T)
{
	long parse_index;
	return unserialize!T(data , parse_index);
}

T unserialize(T )(const byte[] data , out long parse_index) if(isScalarType!T && !isBigSignedType!T && !isBigUnsignedType!T)
{
	assert( cast(byte)T.sizeof == getbasicsize(data[0]));
	
	T value;
	memcpy(&value , data.ptr + 1 , T.sizeof);
	
	parse_index = T.sizeof + 1;
	return value;
}

size_t getsize(T)(T t) if(isScalarType!T && !isBigSignedType!T && !isBigUnsignedType!T)
{
	return T.sizeof + 1;
}



///////////////////////////////////////////////////////////
// variant
// type 		  size
//  5 (4)    - 		
//  6 (8)	 -
//	data
///////////////////////////////////////////////////////////
byte[] serialize(T)(T t)  if( isBigSignedType!T || isBigUnsignedType!T)
{
	byte[] data = toVariant!T(t);
	long index;
	byte[1] h;
	h[0] = (T.sizeof == 4) ? 5 : 8;
	return h ~ data;
}

T unserialize(T )(const byte[] data )  if( isBigSignedType!T || isBigUnsignedType!T)
{
	long parse_index;
	return unserialize!T(data , parse_index);
}

T unserialize(T )(const byte[] data , out long parse_index) if( isBigSignedType!T || isBigUnsignedType!T)
{
	assert( (T.sizeof == 4 ? 5 : 8 ) == data[0]);
	long index;
	T t = toT!T(data[1 .. $] , index);
	parse_index = index + 1;
	return t;
}

size_t getsize(T)(T t) if(isBigSignedType!T) 
{
	return getbytenums(abs(t)) + 1;
}


size_t getsize(T)(T t) if(isBigUnsignedType!T) 
{
	return getbytenum(abs(t)) + 1;
}



// TString
// 1 type 7
// [uint] variant 
//  data

byte[] serialize(T)(T str) if(is(T  == string))
{
	byte[] data;
	uint len = cast(uint)str.length;
	byte[] dlen = toVariant(len);
	data.length = 1 + dlen.length + len;
	
	data[0] = 7;
	memcpy(data.ptr + 1 , dlen.ptr , dlen.length);
	memcpy(data.ptr + 1 + dlen.length , str.ptr, len);
	return data;
}


string unserialize(T)(const byte[] data ) if(is(T == string))
{
	long parse_index;
	return unserialize!T(data , parse_index);
}

string unserialize(T)(const byte[] data , out long parse_index) if(is(T == string))
{
	assert(data[0] == 7);
	long index;
	uint len = toT!uint(data[1 .. $] , index);
	parse_index += 1 + index + len;
	return cast(T)(data[cast(size_t)(1 + index) .. cast(size_t)parse_index].dup);
}

size_t getsize(string str ) 
{
	uint len = cast(uint)str.length;
	return cast(size_t)(1 + toVariant(len).length + str.length);
}


// TUnion			don't support TUnion
// 1 type 6
// 1 len 
// 	 data


/*
byte[] serialize(T)(T t) if(is(T == union))
{
	byte[] data;
	data.length = T.sizeof + 2;
	data[0] = 5;
	data[1] = T.sizeof;
	memcpy(data.ptr + 2 , &t , T.sizeof);
	return data;
}

T unserialize(T)(const byte[] data ) if(is(T == union))
{
	long parser_index;
	return unserialize!T(data , parser_index);
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

*/






// TSArray
// 1 type 8
// size[uint] variant
// len[uint] variant
// data

byte[] serialize(T)( T t) if(isStaticArray!T)
{
	byte[1] header;
	header[0] = 8;
	uint uSize = cast(uint)t.length;
	byte[] dh = cast(byte[])header;
	dh ~= toVariant(uSize);
	
	byte[] data;
	for(size_t i = 0 ; i < uSize ; i++)
	{
		data ~= serialize(t[i]);
	}
	uint len = cast(uint)data.length;
	dh ~= toVariant(len);
	return dh ~ data;
}

T unserialize(T)(const byte[] data ) if(isStaticArray!T)
{
	long parse_index;
	
	return unserialize!T(data , parse_index);
}

T unserialize(T)(const byte[] data , out long parse_index) if(isStaticArray!T)
{
	assert(data[0] == 8);
	T value;
	uint uSize;
	uint len;
	long index1;
	long index2;
	uSize = toT!uint(data[1 .. $] , index1);
	
	len = toT!uint(data[cast(size_t)(index1 + 1) .. $] , index2);
	parse_index += 1 + index1 + index2;
	
	long index = parse_index;
	long parse = 0;
	for(size_t i = 0 ; i < uSize ; i++)
	{
		parse = 0;
		value[i] = unserialize!(typeof(value[0]))(data[cast(size_t)index .. data.length] , parse);
		index += parse;
	}
	
	parse_index += len;
	
	return value;
}

size_t getsize(T)( T t) if(isStaticArray!T)
{
	long total = 1;
	total += getbytenum(t.length);
	for(size_t i = 0 ; i < uSize ; i++)
	{
		total += getsize(t[i]);
	}
	total += getbytenum(total);
	return total;
}






//  TDArray
// 1  type 9
// size[uint]	variant
// length[uint]	variant
// data

byte[] serialize(T)( T t) if(isDynamicArray!T && !is(T == string))
{
	byte[1] header;
	header[0] = 9;
	
	
	uint uSize = cast(uint)t.length;
	byte[] dh = cast(byte[])header;
	dh ~= toVariant(uSize);
	
	byte[] data;
	for(size_t i = 0 ; i < uSize ; i++)
	{
		data ~= serialize(t[i]);
	}
	uint len = cast(uint)data.length;
	dh ~= toVariant(len);
	
	return dh ~ data;
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
	uint uSize;
	uint len;
	long index1;
	long index2;
	uSize = toT!uint(data[1 .. $]  , index1);
	len = toT!uint(data[cast(size_t)(1 + index1) .. $] , index2);
	
	parse_index += 1 + index1 + index2;
	value.length = uSize;
	ulong index = parse_index;
	long parse = 0;
	for(size_t i = 0 ; i < uSize ; i++)
	{
		value[i] = unserialize!(typeof(value[0]))(data[cast(size_t)index .. data.length] , parse);
		index += parse;
	}
	parse_index += len;
	
	return value;
}


size_t getsize(T)( T t) if(isDynamicArray!T && !is(T == string))
{
	long total = 1;
	total += getbytenum(t.length);
	for(size_t i = 0 ; i < uSize ; i++)
	{
		total += getsize(t[i]);
	}
	total += getbytenum(total);
	return total;
}





// TStruct
// 1 type 10
// [uint] variant
// data

byte[] serialize(T)(T t) if(is(T == struct))
{
	byte[1] header;
	header[0] = 6;
	byte[] 	data;
	
	mixin(serializeMembers!T());
	byte [] dh = cast(byte[])header;
	uint len = cast(uint)data.length;
	dh ~= toVariant(len);
	return dh ~ data;
}


T unserialize(T)(const byte[] data , out long parse_index) if(is(T == struct))
{
	assert(data[0] == 6);
	
	T t;
	long index1;
	uint len = toT!uint(data[1 .. $] , index1);
	
	parse_index = 1 + index1 + len;
	long index = 1 + index1;
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
	long total = 1;
	
	mixin(getsizeMembers!T());
	
	total += getbytenum(total);
	return cast(uint)total;
}


// TClass
// 1 type 11
// [uint] len variant
//	data

byte[] serialize(T)(T t) if(is(T == class))
{
	byte[1] header;
	header[0] = 7;
	byte[] 	data;
	byte[] dh = cast(byte[])header;
	mixin(serializeMembers!T());
	
	uint len = cast(uint)data.length;
	dh ~= toVariant(len);
	return dh ~ data;
}


T unserialize(T)(const byte[] data , out long parse_index)if(is(T == class))
{
	assert(data[0] == 7);
	
	T t = new T;
	long index1;
	uint len = toT!uint(data[1 .. $] , index1);
	
	parse_index = index1 + 1 + len;
	long index = index1 + 1;
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
	long total = 1;
	
	mixin(getsizeMembers!T());
	
	total += getbytenum(total);
	
	return total;
}


// only for , nested , new T
version(unittest)
{
	//test struct
	
	void test1(T)(T t)
	{
		assert(unserialize!T(serialize(t)) == t);
	}
	
	struct T1
	{
		bool  		b;
		byte  		ib;
		ubyte 		ub;
		short 		ish;
		ushort 		ush;
		int			ii;
		uint		ui;
		long		il;
		ulong		ul;
		string		s;
		uint[10]	sa;
		long[]		sb;
	}
	
	struct T2
	{
		string	n;
		T1[] 	t;
	}
	
	struct T3
	{
		T1 t1;
		T2 t2;
		string[] name;
	}
	
	//test class
	class C
	{
		int age;
		string name;
		T3	t3;
		override bool opEquals(Object c) {
			auto c1 = cast(C)c;
			return age == c1.age && name == c1.name && t3 == c1.t3;
		}
		
		C clone()
		{
			auto c = new C();
			c.age = age;
			c.name = name;
			c.t3 = t3;
			return c;
		}
		
	}
	
	
	class C2
	{
		C[] c;
		C 	c1;
		T1 	t1;
		
		
		override bool opEquals(Object c) {
			auto c2 = cast(C2)c;
			return this.c == c2.c && c1 == c2.c1 && t1 == c2.t1;
		}
	}
	
	void test_struct_class()
	{
		T1 t;
		t.b = true;
		t.ib = -11;
		t.ub = 128 + 50;
		t.ish = - 50;
		t.ush = (1 << 15) + 50;
		t.ii = - 50;
		t.ui =  (1 << 31) + 50;
		t.il = (cast(long)1 << 63) - 50;
		t.ul = (cast(long)1 << 63) + 50;
		t.s = "test";
		t.sa[0] = 10;
		t.sa[1] = 100;
		t.sb ~= 10;
		t.sb ~= 100;
		test1(t);
		
		T2 t2;
		t2.t ~= t;
		t2.t ~= t;
		t2.n = "testt2";
		test1(t2);
		
		T3 t3;
		t3.t1 = t;
		t3.t2 = t2;
		t3.name ~= "123";
		t3.name ~= "456";
		test1(t3);
		
		C c1 = new C();
		c1.age = 100;
		c1.name = "test";
		c1.t3 = t3;
		
		test1(c1);
		
		C2 c2 = new C2();
		c2.c ~= c1;
		c2.c ~= c1.clone();
		c2.c1 = c1.clone();
		c2.t1 = t;
		
		test1(c2);
	}
}

unittest{
	import std.stdio;
	long index;
	
	
	
	void test(T)(T v)
	{
		long index;
		byte[] bs = toVariant(v);
		long length = bs.length;
		bs ~= [ 'x' ,'y' ];
		return assert(toT!T(bs, index) == v && index == length);
	}
	
	
	
	//test variant
	
	//unsigned
	{
		ubyte j0 = 0;
		ubyte j1 = 50;
		ubyte j2 = (1 << 7) + 50;
		ubyte j3 = 0xFF;
		
		ushort j4 = (1 << 14) + 50;
		ushort j5 = 0xFFFF;
		
		
		uint j6 = (1 << 21) + 50;
		uint j7 = (1 << 28) + 50;
		uint j8 = j6 + j7;
		uint j9 = 0xFFFFFFFF;
		
		ulong j10 = (cast(ulong)1 << 35) + 50;
		ulong j11 = (cast(ulong)1 << 42) + 50;
		ulong j12 = (cast(ulong)1 << 49) + 50;
		ulong j13 = (cast(ulong)1 << 56) + 50;
		ulong j14 = j9 + j10 + j11 + j12;
		ulong j15 = 0xFFFFFFFFFFFFFFFF;
		test(j0);
		test(j1);
		test(j2);
		test(j3);
		test(j4);
		test(j5);
		test(j6);
		test(j7);
		test(j8);
		test(j9);
		test(j10);
		test(j11);
		test(j12);
		test(j13);
		test(j14);
		test(j15);
	}
	
	//signed
	{
		byte i0 = 0;
		byte i1 = (1 << 6) + 50 ;
		byte i2 = (1 << 7) -1;
		byte i3 = -i2;
		byte i4 = -i1;
		
		test(i0);
		test(i1);
		test(i2);
		test(i3);
		test(i4);
		
		short i5 = (1 << 7) + 50;
		short i6 = (1 << 14) + 50;
		short i7 = -i5;
		short i8 = -i6;
		
		
		test(i5);
		test(i6);
		test(i7);
		test(i8);
		
		int i9 = (1 << 16) + 50;
		int i10 = (1 << 25) + 50;
		int i11 = (1 << 30) + 50;
		int i12 = -i9;
		int i13 = -i10;
		int i14 = -i11;
		int i15 = i9 + i10 + i11;
		int i16 = -i15;
		
		test(i9);
		test(i10);
		test(i11);
		test(i12);
		test(i13);
		test(i14);
		test(i15);
		test(i16);
		
		long i17 = (cast(long)1 << 32) + 50;
		long i18 = (cast(long)1 << 48) + 50;
		long i19 = (cast(long)1 << 63) + 50;
		long i20 = i17 + i18 + i19;
		long i21 = -i17;
		long i22 = -i20;
		
		test(i17);
		test(i18);
		test(i19);
		test(i20);
		test(i21);
		test(i22);
		
		int i23 = -11;
		test(i23);
	}
	
	//test serialize
	
	
	//basic: byte ubyte short ushort int uint long ulong
	{
		byte b1 = 123;
		byte b2 = -11;
		ubyte b3 = 233;
		
		
		short s1 = -11;
		short s2 = (1 << 8) + 50;
		short s3 = (1 << 15) - 50;
		ushort s4 = (1 << 16) - 50;
		
		int i1 = -11;
		int i2 = (1 << 16) + 50;
		int i3 = (1 << 31) - 50;
		uint i4 = (1 << 31) + 50;
		
		long l1 = -11;
		long l2 = (cast(long)1 << 32) + 50;
		long l3 = (cast(long)1 << 63) - 50;
		ulong l4 = (cast(long)1 << 63) + 50;
		
		test1(b1);
		test1(b2);
		test1(b3);
		
		test1(s1);
		test1(s2);
		test1(s3);
		test1(s4);
		
		test1(i1);
		test1(i2);
		test1(i3);
		test1(i4);
		
		test1(l1);
		test1(l2);
		test1(l3);
		test1(l4);
	}
	
	//test string
	{
		string s1 = "";
		string s2 = "1";
		string s3 = "123";
		test1(s1);
		test1(s2);
		test1(s3);
	}
	
	//test static arrary
	{
		string[5] sa;
		sa[0] = "test0";
		sa[1] = "test1";
		sa[2] = "test2";
		sa[3] = "test3";
		sa[4] = "test4";
		test1(sa);
	}
	
	//test dynamic arrary
	{
		string[] sa;
		sa ~= "test1";
		sa ~= "test2";
		sa ~= "test3";
		sa ~= "test4";
		
		test1(sa);
	}
	
	//test struct and class
	test_struct_class();
}