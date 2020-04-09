module hunt.serialization.BinaryDeserializer;

import hunt.serialization.specify;
import std.traits;

struct BinaryDeserializer {

  private
  {
     const (ubyte)[] _buffer;
  }

  this (ubyte[]  buffer)
  {
      this._buffer = buffer;
  }


  T iArchive(T)() if(!isDynamicArray!T && !isAssociativeArray!T && !is(T == class) && __traits(compiles, T()))
  {
      T obj;
      specify (this, obj);
      return obj;
  }

  T iArchive(T)() if(!isDynamicArray!T && !isAssociativeArray!T &&!is(T == class) && !__traits(compiles, T()))
  {
    T obj = void;
    specify (this, obj);
    return obj;
  }

  T iArchive(T, A...)(A args) if(is(T == class))
  {
      T obj = new T(args);
      specify(this, obj);
      return obj;
  }

   T iArchive(T)() if(isDynamicArray!T || isAssociativeArray!T)
   {
        return iArchive!(T, ushort)();
   }

   T iArchive(T , U)() if(isDynamicArray!T || isAssociativeArray!T)
   {
        T obj;
        specify!U(this, obj);
        return obj;
   }

    void putUbyte(ref ubyte val)
    {
        val = _buffer[0];
        _buffer = _buffer[1..$];
    }


    void putClass(T)(T val) if(is(T == class))
    {
        specifyClass(this, val);
    }

    auto putRaw(ushort length) {
      auto res = _buffer[0 .. length];
      _buffer = _buffer[length .. $];
      return res;
    }
}
