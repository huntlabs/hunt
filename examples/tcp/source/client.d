import hunt.io.ByteBuffer;
import hunt.event;
import hunt.io.TcpStream;
import hunt.io.IoError;
import hunt.logging;

import core.thread;
import core.time;
import std.parallelism;
import std.socket;
import std.stdio;

 enum Host = "127.0.0.1";
// enum Host = "10.1.222.110";
enum Port = 8080;

void main() {
	trace("Start test...");
	EventLoop loop = new EventLoop();

	TcpStream client = new TcpStream(loop);
	int count = 10;
	client.connected((bool isSucceeded) {
		if (isSucceeded) {
			writeln("connected with: ", client.remoteAddress.toString());
			string data = "Hello world!";
			debug writeln("sending: size=", data.length, "  content: ", data);
			client.write(cast(const(ubyte[])) data);
		} else {
			warning("The connection failed!");
			auto runTask = task(() {
				Thread.sleep(client.options.retryInterval);
				client.reconnect();
			});
			taskPool.put(runTask);
		}
	}).received((ByteBuffer buffer) {
		byte[] data = buffer.getRemaining();
		writeln("received data: ", cast(string) data);
		if (--count > 0) {
			debug writeln("sending: size=", data.length, "  content: ", cast(string) data);
			client.write(cast(ubyte[]) data);
		} else {
			client.close();
		}
	}).closed(() { 
		writeln("The connection closed!"); loop.stop(); 
	}).error((IoError error) {
		writefln("error occurred: %d  %s", error.errorCode, error.errorMsg);
	}).connect(Host, Port);

	loop.run(100);
}
