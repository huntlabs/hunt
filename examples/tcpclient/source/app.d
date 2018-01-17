import std.stdio;

import kiss.event;
import kiss.net.TcpStreamClient;
import kiss.exception;

void main()
{
	writeln("Edit source/app.d to start your project.");
	EventLoop loop = new EventLoop();
	TcpStreamClient client = new TcpStreamClient(loop);
	client.setConnectHandle((bool connect)nothrow @trusted{
		catchAndLogException((){
			if(connect){
				writeln("链接成功！！");
				client.write(new WarpStreamBuffer(cast(const(ubyte[]))"hello world!",(in ubyte[] wdata, size_t size) @trusted nothrow{
									catchAndLogException((){
										writeln("Writed Suessed Size : ", size, "  Data : ", cast(string)wdata);
									}());
								}));

			} else {
				writeln("链接失败！！");
				loop.stop;
			}
		}());
	}).setReadHandle((in ubyte[] data)@trusted nothrow {
						catchAndLogException((){
							writeln("read Data: ", cast(string)data);

							client.write(new WarpStreamBuffer(data.dup,(in ubyte[] wdata, size_t size) @trusted nothrow{
									catchAndLogException((){
										writeln("Writed Suessed Size : ", size, "  Data : ", cast(string)wdata);
									}());
								}));
						}());
					}).setCloseHandle(()@trusted nothrow {
						catchAndLogException((){
							writeln("The Socket is Cloesed!");
						}());
					});
	client.connect(parseAddress("127.0.0.1",8096));
	loop.join();
}
