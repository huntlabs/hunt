
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
			string data = "Hello world!";
			debug writeln("sending: size=", data.length, "  content: ", data);
			client.write(cast(const(ubyte[])) data);
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
	}).onDataWritten((Object obj) {
		writefln("Data write done");
	}).onDataReceived((ByteBuffer buffer) {
		byte[] data = buffer.getRawData();
		writeln("received data: ", cast(string)data);
		if (--count > 0) {
			debug writeln("sending: size=", data.length, "  content: ", cast(string) data);
			client.write(cast(ubyte[])data);
			// client.write(new SocketStreamBuffer(data.dup, (in ubyte[] wdata, size_t size) {
			// 		debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
			// 	}));
		} else {
			client.close();
		}
	}).onClosed(() {
		writeln("The connection closed!");
		loop.stop();
	}).onError((string msg){
		writefln("error occurred: %s", msg);
	})
	.connect("127.0.0.1", 8080);
	// }).connect("::1", 8080);
	// }).connect("fe80::b6f0:24f9:9b3b:9f28%ens33", 8080);
	// }).connect("fe80::2435:c2f0:4a2e:ba11%ens33", 8080);

	loop.run();

	// loop.runAsync(20);
	// writeln("The app will exit in 5 seconds!");
	// import core.thread;
	// import core.time;
	// Thread.sleep(5.seconds);
	// loop.stop();	
}
