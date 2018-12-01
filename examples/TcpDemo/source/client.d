import std.stdio;

import hunt.event;
import hunt.io.TcpStream;
// import hunt.logging;
import std.socket;

void main()
{
	EventLoop loop = new EventLoop();
	// TcpStream client = new TcpStream(loop, AddressFamily.INET6);
	TcpStream client = new TcpStream(loop, AddressFamily.INET);
	int count = 10;
	client.onConnected((bool isSucceeded) {
		if (isSucceeded)
		{
			writeln("connected with: ", client.remoteAddress.toString()); 
			client.write(cast(const(ubyte[])) "Hello world!", (in ubyte[] wdata, size_t size) {
				debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
			});

			// client.write(new SocketStreamBuffer(cast(const(ubyte[])) "hello world!",
			// 	(in ubyte[] wdata, size_t size) {
			// 		debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
			// 	}));
		}
		else
		{
			writeln("The connection failed!");
			loop.stop();
		}
	}).onDataReceived((in ubyte[] data) {
		writeln("received data: ", cast(string) data);
		if(--count > 0) {
			client.write(data, (in ubyte[] wdata, size_t size) {
				debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
			});
		// client.write(new SocketStreamBuffer(data.dup, (in ubyte[] wdata, size_t size) {
		// 		debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
		// 	}));
		}
	}).onClosed(() {
		writeln("The connection is closed!");
		loop.stop();
	}).connect("127.0.0.1", 8090);
	// }).connect("::1", 8090);
	// }).connect("fe80::b6f0:24f9:9b3b:9f28%ens33", 8090);
	// }).connect("fe80::2435:c2f0:4a2e:ba11%ens33", 8090);
	

	loop.run();
}
