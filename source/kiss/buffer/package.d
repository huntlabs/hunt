module kiss.buffer;

interface  WriteBuffer 
{
	size_t write(in ubyte[] data);

	size_t set(size_t pos, in ubyte[] data);

	@property size_t length() const;
}

interface  ReadBuffer 
{
	@property bool eof() const;

	size_t read(size_t size, scope void delegate(in ubyte[]) cback);

	void rest(size_t size = 0);

	size_t readPos();

	@property size_t length() const;
}

interface Buffer : WriteBuffer, ReadBuffer
{
	size_t readLine(scope void delegate(in ubyte[]) cback); //回调模式，数据不copy
	
	size_t readAll(scope void delegate(in ubyte[]) cback);
	
	size_t readUtil(in ubyte[] data, scope void delegate(in ubyte[]) cback);
}
