
import hunt.collection.ByteBuffer;
import hunt.event;
import hunt.io.TcpStream;
import hunt.logging;

import core.thread;
import core.time;
import std.parallelism;
import std.socket;
import std.stdio;


void main() {
	trace("Start test...");
	EventLoop loop = new EventLoop();

	// TcpStream client = new TcpStream(loop, AddressFamily.INET6);
	TcpStream client = new TcpStream(loop, AddressFamily.INET);
	int count = 10;
	client.onConnected((bool isSucceeded) {
		if (isSucceeded) {
			writeln("connected with: ", client.remoteAddress.toString());
			client.write(cast(const(ubyte[])) "Hello world!", (in ubyte[] wdata, size_t size) {
				debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
			});
			// client.write(new SocketStreamBuffer(cast(const(ubyte[])) "hello world!",
			// 	(in ubyte[] wdata, size_t size) {
			// 		debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
			// 	}));
		} else {
			warning("The connection failed!");
			// loop.stop();

			// Thread.sleep(client.options.retryInterval);
			// client.reconnect();

			auto runTask = task((){ 
				Thread.sleep(client.options.retryInterval);
				client.reconnect();
			});
        	taskPool.put(runTask);
		}
	}).onDataReceived((ByteBuffer buffer) {
		byte[] data = buffer.getRawData();
		writeln("received data: ", cast(string)data);
		if (--count > 0) {
			client.write(cast(ubyte[])data, (in ubyte[] wdata, size_t size) {
				debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
			});
			// client.write(new SocketStreamBuffer(data.dup, (in ubyte[] wdata, size_t size) {
			// 		debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
			// 	}));
		}
	}).onClosed(() {
		writeln("The connection closed!");
		loop.stop();
	}).connect("127.0.0.1", 8080);
	// }).connect("::1", 8080);
	// }).connect("fe80::b6f0:24f9:9b3b:9f28%ens33", 8080);
	// }).connect("fe80::2435:c2f0:4a2e:ba11%ens33", 8080);

	loop.run();

	// loop.runAsync(20);
	// writeln("The app will exit in 10 seconds!");
	// import core.thread;
	// import core.time;
	// Thread.sleep(10.seconds);
	// loop.stop();	
}
