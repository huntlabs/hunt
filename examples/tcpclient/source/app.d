import std.stdio;
import kiss.event.task;
import kiss.event;
import kiss.net.TcpStream;
import kiss.exception;

void main()
{
	writeln("Edit source/app.d to start your project.");
	EventLoop loop = new EventLoop();
	TcpStream client = new TcpStream(loop);
	client.setConnectHandle((bool connect)nothrow @trusted{
		catchAndLogException((){
			if(connect){
				writeln("链接成功！！");
				int xxx = 0;
				client.write(new WarpStreamBuffer(cast(const(ubyte[]))"hello world!",(in ubyte[] wdata, size_t size) @trusted nothrow{
											catchAndLogException((){
												if (wdata.length == size)
													writeln("Writed Suessed index : ", xxx++);
											}());
										}));
				// int xxx = 0;
				// for(int i = 0; i < 1000000; i ++) {
				// 	void tmp() {
				// 		client.write(new WarpStreamBuffer(cast(const(ubyte[]))"hello world!",(in ubyte[] wdata, size_t size) @trusted nothrow{
				// 							catchAndLogException((){
				// 								if (wdata.length == size)
				// 									writeln("Writed Suessed index : ", xxx++);
				// 							}());
				// 						}));
				// 	}
				// 	loop.postTask(newTask(&tmp));
				// }

			} else {
				writeln("链接失败！！");
				loop.stop;
			}
		}());
	}).setReadHandle((in ubyte[] data)@trusted nothrow {
						catchAndLogException((){
							// writeln("read Data: ", cast(string)data);

							client.write(new WarpStreamBuffer(data.dup,(in ubyte[] wdata, size_t size) @trusted nothrow{
									catchAndLogException((){
										// writeln("Writed Suessed Size : ", size, "  Data : ", cast(string)wdata);
									}());
								}));
						}());
					}).setCloseHandle(()@trusted nothrow {
						catchAndLogException((){
							writeln("The Socket is Cloesed!");
						}());
					});
	client.connect(parseAddress("10.1.222.120",8096));
	loop.join();
}
