module binary.serialization.specify;

import std.traits;
import std.range;
import binary.serialization.BinarySerializer;
import binary.serialization.BinaryDeserializer;

template PtrType(T) {
  static if(is(T == bool) || is(T == char)) {
    alias PtrType = ubyte*;
  } else static if(is(T == float)) {
    alias PtrType = uint*;
  } else static if(is(T == double)) {
      alias PtrType = ulong*;
    } else {
      alias PtrType = Unsigned!T*;
    }
}


void specify(C, T)(auto ref C obj, ref T val) if(is(T == wchar)) {
  specify(obj , *cast(ushort*)&val);
}

void specify(C, T)(auto ref C obj, ref T val) if(is(T == dchar)) {
  specify(obj , *cast(uint*)&val);
}

void specify(C, T)(auto ref C obj, ref T val) if(is(T == ushort)) {
  ubyte valh = (val >> 8);
  ubyte vall = val & 0xff;
  obj.putUbyte(valh);
  obj.putUbyte(vall);
  val = (valh << 8) + vall;
}

void specify(C, T)(auto ref C obj, ref T val) if(is(T == uint)) {
  ubyte val0 = (val >> 24);
  ubyte val1 = cast(ubyte)(val >> 16);
  ubyte val2 = cast(ubyte)(val >> 8);
  ubyte val3 = val & 0xff;
  obj.putUbyte(val0);
  obj.putUbyte(val1);
  obj.putUbyte(val2);
  obj.putUbyte(val3);
  val = (val0 << 24) + (val1 << 16) + (val2 << 8) + val3;
}

void specify(C, T)(auto ref C obj, ref T val) if(is(T == ulong)) {
  T newVal;
  for(int i = 0; i < T.sizeof; ++i) {
    immutable shiftBy = 64 - (i + 1) * T.sizeof;
    ubyte byteVal = (val >> shiftBy) & 0xff;
    obj.putUbyte(byteVal);
    newVal |= (cast(T)byteVal << shiftBy);
  }
  val = newVal;
}

//静态数组
void specify(C, T)(auto ref C obj, ref T val) if(isStaticArray!T) {
  static if(is(Unqual!(ElementType!T): ubyte) && T.sizeof == 1)
  {
    obj.putRaw(cast(ubyte[])val);
  }
  else
  {
    foreach(ref v; val)
    {
      specify(obj ,v);
    }
  }
}

//string
void specify(C, T)(auto ref C obj, ref T val) if(is(T == string))
{
  ushort len = cast(ushort)val.length;
  specify(obj , len);

  static if (is (C == BinarySerializer))
  {
    obj.putRaw(cast(ubyte[])val);
  }
  else
  {
    val = cast(string) obj.putRaw(len).idup;
  }
}

//基础类型数组
void specify(C, T)(auto ref C obj, ref T val) if(isAssociativeArray!T)
{
  ushort length = cast(ushort)val.length;
  specify(obj , length);
  const keys = val.keys;
  for(ushort i = 0; i < length; ++i) {
    KeyType!T k = keys.length ? keys[i] : KeyType!T.init;
    auto v = keys.length ? val[k] : ValueType!T.init;

    specify(obj ,k);
    specify(obj ,v);
    val[k] = v;
  }
}

void specify(C, T)(auto ref C obj, ref T val) if(isPointer!T) {
  alias ValueType = PointerTarget!T;
  specify(obj , *val);
}



//ubyte
void specify(C, T)(auto ref C obj, ref T val) if(is(T == ubyte))
{
  obj.putUbyte(val);
}

//有符号类型
void specify(C, T)(auto ref C obj, ref T val) if(!is(T == enum) && (isSigned!T || isBoolean!T || is(T == char) || isFloatingPoint!T))
{
  specifyPtr(obj , val);
}

//ENUM
void specify(C, T)(auto ref C obj, ref T val) if(is(T == enum))
{
  specify(obj , cast(Unqual!(OriginalType!(T)))val );
}

void specify(C, T)(auto ref C obj, ref T val) if(is(C == BinarySerializer) && isInputRange!T && !isInfinite!T && !is(T == string) && !isStaticArray!T && !isAssociativeArray!T)
{
  enum hasLength = is(typeof(() { auto l = val.length; }));
  ushort length = cast(ushort)val.length;
  specify(obj, length);

  static if(hasSlicing!(Unqual!T) && is(Unqual!(ElementType!T): ubyte) && T.sizeof == 1)
  {
    obj.putRaw(cast(ubyte[])val.array);
  }
  else
  {
    foreach(ref v; val)
    {
      specify(obj , v);
    }
  }
}


void specify(C, T)(auto ref C obj, ref T val) if(isAggregateType!T && !isInputRange!T && !isOutputRange!(T, ubyte))
{
  loopMembers(obj , val);
}

//自定义数组
void specify(C, T)(auto ref C obj, ref T val) if(isDecerealiser!C && !isOutputRange!(T, ubyte) && isDynamicArray!T && !is(T == string)) {
  ushort length;

  specify(obj,length);
  decerealiseArrayImpl(obj, val, length);
}

void decerealiseArrayImpl(C, T, U)(auto ref C obj, ref T val, U length) if(is(T == E[], E) && isDecerealiser!C)
{

  ulong neededBytes(T)(ulong length) {
    alias E = ElementType!T;
    static if(isScalarType!E)
      return length * E.sizeof;
    else static if(isInputRange!E)
      return neededBytes!E(length);
    else
      return 0;
  }

  immutable needed = neededBytes!T(length);

  static if(is(Unqual!(ElementType!T): ubyte) && T.sizeof == 1) {
    val = obj.putRaw(length).dup;
  } else {
    if(val.length != length) val.length = cast(uint)length;
    foreach(ref e; val) obj.specify(e);
  }
}


void specifyPtr(C, T)(auto ref C obj, ref T val)
{
  auto ptr = cast(PtrType!T)(&val);
  specify(obj , *ptr);
}

void loopMembers(C, T)(auto ref C obj, ref T val) if(is(T == struct))
{
  loopMembersImpl!T(obj , val);
}

void loopMembers(C, T)(auto ref C obj, ref T val) if(is(T == class))
{
  static if(is(typeof(() { val = new T; }))) {
    if(val is null) val = new T;
  } else {
  }

  obj.putClass(val);
}



void loopMembersImpl(T, C, VT) (auto ref C obj, ref VT val)
{
  foreach(member; __traits(derivedMembers, T)) {
    enum isMemberVariable = is(typeof(() {
      __traits(getMember, val, member) = __traits(getMember, val, member).init;
    }));
    static if(isMemberVariable) {
      specifyAggregateMember!member(obj , val);
    }
  }
}

void specifyAggregateMember(string member, C, T)(auto ref C obj, ref T val)
{
  import std.meta: staticIndexOf;
  enum NoCereal;
  enum noCerealIndex = staticIndexOf!(NoCereal, __traits(getAttributes,__traits(getMember, val, member)));
  static if(noCerealIndex == -1) {
    specifyMember!member(obj, val);
  }
}

void specifyMember(string member, C, T)(auto ref C obj, ref T val)
{
  specify( obj , __traits(getMember, val, member));
}

void specifyBaseClass(C, T)(auto ref C obj, ref T val) if(is(T == class))
{
  foreach(base; BaseTypeTuple!T)
  {
    loopMembersImpl!base(obj ,val);
  }
}


void specifyClass(C, T)(auto ref C obj, ref T val) if(is(T == class))
{
  specifyBaseClass(obj, val);
  loopMembersImpl!T(obj, val);
}

void checkDecerealiser(T)() {
  //static assert(T.type == CerealType.ReadBytes);
  auto dec = T();
  ulong bl = dec.bytesLeft;
}

enum isDecerealiser(T) =  (is (T == BinaryDeserializer) && is(typeof(checkDecerealiser!T))) ;
