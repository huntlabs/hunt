module kiss.container.common;

import core.atomic;
import std.traits : Unqual;
import std.experimental.allocator;

template StaticAlloc(ALLOC)
{
    enum StaticAlloc = (stateSize!ALLOC == 0);
}

mixin template AllocDefine(ALLOC)
{
    static if (StaticAlloc!ALLOC) {
        alias _alloc = ALLOC.instance;
        alias Alloc = typeof(ALLOC.instance);
    } else {
        alias Alloc = ALLOC;
        private ALLOC _alloc;
        public @property ALLOC allocator() {
            return _alloc;
        }
    }
}

struct RefCount
{
    pragma(inline)
    uint refCnt() shared nothrow @nogc
    {
        return atomicOp!("+=")(_count, 1);
    }

    pragma(inline)
    uint derefCnt()  shared nothrow @nogc
    {
        return atomicOp!("-=")(_count, 1);
    }

    pragma(inline)
    uint count()  shared nothrow @nogc
    {
        return atomicLoad(_count);
    }

private:
    shared uint _count = 1;
}

mixin template Refcount()
{
    static typeof(this) * allocate(ALLOC)(auto ref ALLOC alloc){
        return alloc.make!(typeof(this))();
    }

    static void deallocate(ALLOC)(auto ref ALLOC alloc, typeof(this) * dd) nothrow {  
        try
        {
            alloc.dispose(dd);
        } 
        catch(Exception)
        {}
    }

    static void inf(typeof(this) * dd)
    {
        if(dd is null) return;
        dd._count.refCnt();
    }

    static typeof(this) * deInf(ALLOC)(auto ref ALLOC alloc, typeof(this) * dd) nothrow
    {
        if(dd is null) return dd;
        if(dd._count.derefCnt() == 0){
            deallocate!ALLOC(alloc,dd);
            return null;
        }
        return dd;
    }
    @property uint count(){return _count.count();}
    @disable this(this);
    private shared RefCount _count;
}

/// Array Cow Data
struct ArrayCOWData(T, Allocator,bool inGC = false)  if(is(T == Unqual!T))
{
    import core.memory : GC;
    import std.exception : enforce;
    import core.stdc.string : memcpy;
    import kiss.array : fillWithMemcpy;

    ~this()
    {
        destoryBuffer();
    }

    bool reserve(size_t elements) {
        if (elements <= data.length)
            return false;
        size_t len = _alloc.goodAllocSize(elements * T.sizeof);
        elements = len / T.sizeof;
        void[] varray = _alloc.allocate(len);
        auto ptr = cast(T*) enforce(varray.ptr);
        size_t bleng = (data.length * T.sizeof);
        if (data.length > 0) {
            memcpy(ptr, data.ptr, bleng);
        }
        varray = varray[bleng.. len];
        fillWithMemcpy!T(varray,T.init);
        static if(inGC){
            GC.addRange(ptr, len);
        }
        destoryBuffer();
        data = ptr[0 .. elements];
        return true;
    }

    pragma(inline, true)
    void destoryBuffer(){
        if (data.ptr) {
            static if(inGC)
                GC.removeRange(data.ptr);
            _alloc.deallocate(data);
        }
    }

    static if (StaticAlloc!Allocator)
        alias _alloc = Allocator.instance;
    else 
        Allocator _alloc;
    T[] data;

    mixin Refcount!();
}
