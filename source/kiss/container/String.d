module kiss.container.String;

import kiss.container.common;
import core.stdc.string : memcpy;
import std.traits;
import std.experimental.allocator;
import std.experimental.allocator.mallocator;
import Range =  std.range.primitives;


alias IString(Alloc)    = StringImpl!(char, Alloc);
alias IWString(Alloc)   = StringImpl!(wchar, Alloc);
alias IDString(Alloc)   = StringImpl!(dchar, Alloc);
alias String    = IString!(Mallocator);
alias WString   = IWString!(Mallocator);
alias DString   = IDString!(Mallocator);

deprecated("Unsupported no more!")
@trusted struct StringImpl(Char, Allocator) 
                if(is(Char == Unqual!Char) && isSomeChar!Char)
{
    alias Data = ArrayCOWData!(Char, Allocator);
    static if (StaticAlloc!Allocator)
    {
        this(const Char[] data)
        {
            assign(data);
        }
    }
    else
    {
        @disable this();
        this(const Char[] data,Allocator alloc)
        {
            _alloc = alloc;
            assign(data);
        }

        this(Allocator alloc)
        {
            _alloc = alloc;
        }
    }

    this(this)
    {
        Data.inf(_data);
    }

    ~this()
    {
        Data.deInf(_alloc, _data);
    }

    typeof(this) opSlice() nothrow {
		return this;
    }

    typeof(this) opSlice(in size_t low, in size_t high) @trusted 
    in{
        assert(low <= high);
		assert(high < _str.length);
    } body{
        auto rv = this;
        rv._str = _str[low .. high];
        return rv;
    }

    Char opIndex(size_t index) const
    in{
        assert(index < _str.length);
    } body{
        return _str[index];
    }

    bool opEquals(S)(S other) const 
		if(is(S == Unqual!(typeof(this))) || is(S : const (Char)[]))
	{
		if(_str.length == other.length){
            for(size_t i = 0; i < _str.length; ++ i) {
                if(_str[i] != other[i]) 
                    return false;
            }
            return true;
        } else
            return false;
    }

    int opCmp(S)(S other) const 
        if(is(S == Unqual!(typeof(this))) || is(S : const (Char)[]))
    {
        auto a = cast(immutable (Char)[])_str;
        auto b = cast(immutable (Char)[])other;

        if(a < b){
            return -1;
        } else if(a > b){
            return 1;
        } else {
            return 0;
        }
    }

    size_t opDollar() nothrow const{return _str.length;}

    mixin AllocDefine!Allocator;

    void opAssign(S)(auto ref S n) if(is(S == Unqual!(typeof(this))) || is(S : const (Char)[])) {
        static if(is(S : const Char[])){
            assign(n);
        } else {
            if(n._data !is _data){
                Data.deInf(_alloc,_data);
                _data = n._data;
                Data.inf(_data);
            }
            _str = n._str;
        }
    }

    @property bool empty() const nothrow {
            return _str.length == 0;
    }

    @property size_t length()const nothrow {return _str.length;}

    int opApply(scope int delegate(Char) dg)
    {
        int result = 0;

        for (size_t i = 0; i < _str.length; i++)
        {
            result = dg(_str[i]);
            if (result)
                break;
        }
        return result;
    }

    int opApply(scope int delegate(size_t, Char) dg)
    {
        int result = 0;

        for (size_t i = 0; i < _str.length; i++)
        {
            result = dg(i, _str[i]);
            if (result) break;
        }
        return result;
    }

    static if(!is(Unqual!Char == dchar)){
         int opApply(scope int delegate(dchar) dg)
         {
             int result = 0;
             immutable(Char)[] str = cast(immutable(Char)[])_str;
             while(!Range.empty(str)){
                result = dg(Range.front(str));
                if (result) break;
                Range.popFront(str);
             }
             return result;
        }
    }

    @property immutable(Char)[] idup() const {
		return _str.idup;
    }

    @property typeof(this) dup() {
		typeof(this) ret = this;
        if(this._data !is null)
            ret.doCOW(0);
        return ret;
    }

    @property auto front() const
    in{
        assert(!this.empty);
    }body{
        return Range.front(_str);
	}

	@property auto back() const
    in{
        assert(!this.empty);
    }body{
        return Range.back(_str);
    }

    @property const(Char) * ptr() const {
        return _str.ptr;
    }

    static if(is(Char == char)){
        @property const(char) * cstr(){
            if(_str.length == 0) {
                return null;
            } else {
                doCOW(1);
                char * ptr = cast(char*)_str.ptr;
                ptr[_str.length] = '\0';
                return ptr;
            }
        }
    }

    immutable(Char)[] opCast(T)() nothrow
        if(is(T == immutable(Char)[]))
    {
        return stdString();
    }

    @property immutable(Char)[] stdString() nothrow {
        return cast(immutable (Char)[])_str;
    }

    typeof(this) opBinary(string op,S)(auto ref S other) 
		if((is(S == Unqual!(typeof(this))) || is(S : const Char[])) && op == "~")
	{
		typeof(this) ret = this;
        ret ~= other;
        return ret;
    }

    void opOpAssign(string op,S)(auto ref S other) 
        if((is(S == Unqual!(typeof(this))) || is(S : const Char[]) || is(Unqual!S == Char)) && op == "~") 
    {
        static if(is(Unqual!S == Char)){
            const size_t tmpLength = 1;
        } else {
            if(other.length == 0) return;
            const size_t tmpLength = other.length;
        }
        doCOW(tmpLength);
        Char * basePtr =  _data.data.ptr + baseLength();
        Char * tptr = basePtr + _str.length;
        static if(is(Unqual!S == Char)){
            tptr[0] = other;
        } else {
            memcpy(tptr, other.ptr, (tmpLength * Char.sizeof));
        }
        size_t len = _str.length + tmpLength;
        _str = basePtr[0..len];
    }

private:
    void assign(const Char[] input)
    {
        if(input.length == 0){
            Data.deInf(_alloc,_data);
            _str = null;
            _data = null;
            return;
        }
        auto data = buildData();
        Data.deInf(_alloc,data);
        _data.reserve(input.length);
        size_t len = input.length * Char.sizeof;
        memcpy(_data.data.ptr, input.ptr, len);
        _str = _data.data[0..input.length];
    }

    Data * buildData(){
        Data* data  = null;
        if(_data !is null && _data.count > 1){
            data = _data;
            _data = null;
        }
        if(_data is null) {
            _data = Data.allocate(_alloc);
            static if(!StaticAlloc!Allocator)
                _data._alloc = _alloc;
        }
        return data;
    }

    size_t baseLength(){
        if((_str.length == 0) || (_str.ptr is _data.data.ptr))
            return 0;
        else
            return cast(size_t)(_str.ptr - _data.data.ptr);
    }

    size_t extenSize(size_t size) {
        if (size > 0)
            size = size > 128 ? size + ((size / 3) * 2) : size * 2;
        else
            size = 32;
        return size;
    }

    void doCOW(size_t tmpLength = 0)
    {
       auto data = buildData();
        if(data !is null) {
            _data.reserve(extenSize(_str.length + tmpLength));
            if(_str.length > 0){
                memcpy(_data.data.ptr, _str.ptr, (_str.length * Char.sizeof));
                _str = _data.data[0.. _str.length];
            }
            Data.deInf(_alloc,data);
        } else if(tmpLength > 0) {
            size_t blen = baseLength();
            if(_data.reserve(extenSize(blen +  _str.length + tmpLength)))
                _str = _data.data[blen.. (blen + _str.length)];
        }
    }

private:
    Data* _data;
    Char[] _str;
}

/*
version(unittest) :

void testFunc(T,size_t Buf)() {
	import std.conv : to;
	import std.stdio : writeln;
	import std.array : empty, popBack, popFront;
    import std.range.primitives;
	import std.format : format;

	auto strs = ["","ABC", "HellWorld", "", "Foobar", 
		"HellWorldHellWorldHellWorldHellWorldHellWorldHellWorldHellWorldHellWorld", 
		"ABCD", "Hello", "HellWorldHellWorld", "ölleä",
		"hello\U00010143\u0100\U00010143", "£$€¥", "öhelloöö"
	];

	foreach(strL; strs) {
		auto str = to!(immutable(T)[])(strL);
		auto s = String(str);

		assert(s.length == str.length);
		assert(s.empty == str.empty);
		assert(s == str);

		auto istr = s.idup();
		assert(str == istr);

		foreach(it; strs) {
			auto cmpS = to!(immutable(T)[])(it);
			auto itStr = String(cmpS);

			if(cmpS == str) {
				assert(s == cmpS);
				assert(s == itStr);
                assert(s <= itStr);
			} else {
				assert(s != cmpS);
				assert(s != itStr);
			}
		}

		if(s.empty) { // if str is empty we do not need to test access
			continue; //methods
		}

		assert(s.front == str.front, to!string(s.front));
		assert(s.back == str.back);
		assert(s[0] == str[0], to!string(s[0]) ~ " " ~ to!string(str.front));
		for(size_t i = 0; i < str.length; ++i) {
			assert(str[i] == s[i]);
		}

		for(size_t it = 0; it < str.length; ++it) {
			for(size_t jt = it; jt < str.length; ++jt) {
				auto ss = s[it .. jt];
				auto strc = str[it .. jt];

				assert(ss.length == strc.length);
				assert(ss.empty == strc.empty);

				for(size_t k = 0; k < ss.length; ++k) {
					assert(ss[k] == strc[k], 
						format("it %s jt %s k %s ss[k] %s strc[k] %s str %s",
							it, jt, k, ss[k], strc[k], str
						)
					);
				}
			}
		}

		String t;
		assert(t.empty);

		t = str;
		assert(s == t);
		assert(!t.empty);
		assert(t.front == str.front, to!string(t.front));
		assert(t.back == str.back);
		assert(t[0] == str[0]);
		assert(t.length == str.length);

		auto tdup = t.dup;
		assert(!tdup.empty);
		assert(tdup.front == str.front, to!string(tdup.front));
		assert(tdup.back == str.back);
		assert(tdup[0] == str[0]);
		assert(tdup.length == str.length);

		istr = t.idup();
		assert(str == istr);

		foreach(it; strs) {
			auto joinStr = to!(immutable(T)[])(it);
			auto itStr = String(joinStr);
			auto compareStr = str ~ joinStr;
            String tdup22 = tdup;
            String tdup23 = tdup;
            tdup22 ~= (joinStr);
            tdup23 ~= itStr;


			auto t2dup = tdup ~ joinStr;
			auto t2dup2 = tdup ~ itStr;

			assert(t2dup.length == compareStr.length);
			assert(t2dup2.length == compareStr.length);
            assert(tdup22.length == compareStr.length);
			assert(tdup23.length == compareStr.length);

			assert(t2dup == compareStr);
			assert(t2dup2 == compareStr);
            assert(tdup22 == compareStr);
			assert(tdup23 == compareStr);
            tdup22 ~= 's';
            tdup23 ~= 's';
            assert(tdup22 == tdup23);
            assert(tdup22 != compareStr);
			assert(tdup23 != compareStr);
		}
	}
}

unittest {
	testFunc!(char,3)();
}*/