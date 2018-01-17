module kiss.buffer.ByteBuffer;

import kiss.buffer;


final class ByteBuffer(Alloc) : Buffer
{
    import kiss.bytes;
    import kiss.container.Vector;
    import std.experimental.allocator.common;

    alias BufferStore = Vector!(ubyte,Alloc); 

	static if (stateSize!(Alloc) != 0)
	{
		this(Alloc alloc)
		{
			_store = BufferStore(1024,alloc);
		}
		
		@property allocator(){return _store.allocator;}
		
	} else {
		this()
		{
			_store = BufferStore(1024);
		}
	}

	~this(){
		destroy(_store);
	}

    pragma(inline,true) void reserve(size_t elements)
	{
		_store.reserve(elements);
	}

	pragma(inline,true) void clear()
	{
		_rsize = 0;
		_store.clear();
	}
	
	override @property bool eof() const
	{
		return (_rsize >= _store.length);
	}

	override size_t read(size_t size,scope  void delegate(in ubyte[]) cback)
	{
		size_t len = _store.length - _rsize;
		len = size < len ? size : len;
		auto _data = _store.data();
		size = _rsize;
		_rsize += len;
		if (len > 0)
			cback(_data[size .. _rsize]);

		return len;
	}
	
	override size_t write(in ubyte[] dt)
	{
		size_t len = _store.length;
		_store.insertBack(cast(ubyte[])dt);
		return _store.length - len;
	}

	override size_t set(size_t pos, in ubyte[] data)
	{
		import core.stdc.string : memcpy;
		if(pos >= _store.length || data.length == 0) return 0;
		size_t len = _store.length - pos;
		len = len > data.length ? data.length : len;
		ubyte * ptr = cast(ubyte *)(_store.ptr + pos);
		memcpy(ptr, data.ptr, len);
		return len;
	}
	
	override void rest(size_t size = 0){
		_rsize = size;
	}
	
	override size_t readPos() {
		return _rsize;
	}
	
	BufferStore allData(){
		return _store;
	}
	
	override @property size_t length() const { return _store.length; }
	
	override size_t readLine(scope void delegate(in ubyte[]) cback) //回调模式，数据不copy
	{
		if(eof()) return 0;
		auto _data = _store.data();
		auto tdata = _data[_rsize..$];
		size_t size = _rsize;
		ptrdiff_t index = findCharByte(tdata,cast(ubyte)'\n');
		if(index < 0){
			_rsize += tdata.length;
			cback(tdata);
		} else {
			_rsize += (index + 1);
			size += 1;
			if(index > 0){
				size_t ts = index -1;
				if(tdata[ts] == cast(ubyte)'\r') {
					index = ts;
				}
			}
			cback(tdata[0..index]);
		}
		
		return _rsize - size;
	}
	
	override size_t readAll(scope void delegate(in ubyte[]) cback)
	{
		if(eof()) return 0;
		auto _data = _store.data();
		auto tdata = _data[_rsize..$];
		_rsize = _store.length;
		cback(tdata);
		return tdata.length;
	}
	
	override size_t readUtil(in ubyte[] chs, scope void delegate(in ubyte[]) cback)
	{
		if(eof()) return 0;
		auto _data = _store.data();
		auto tdata = _data[_rsize..$];
		size_t size = _rsize;
		ptrdiff_t index = findCharBytes(tdata,chs);
		if(index < 0){
			_rsize += tdata.length;
			cback(tdata);
		} else {
			_rsize += (index + chs.length);
			size += chs.length;
			cback(tdata[0..index]);
		}
		return _rsize - size;
	}
	
private:
	BufferStore _store;
	size_t _rsize = 0;
}
