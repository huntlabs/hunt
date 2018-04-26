import std.stdio;

import kiss.event;
import kiss.net.TcpListener;
import kiss.net.TcpStream;
import kiss.util.KissTimer;

import std.socket;
import std.functional;
import std.exception;
import std.datetime;
import std.experimental.logger;
import std.process;

void main()
{

	globalLogLevel(LogLevel.warning);

	debug writefln("Main thread: %s", thisThreadID());

	EventLoop loop = new EventLoop();
	TcpListener listener = new TcpListener(loop, AddressFamily.INET);

	listener.bind(8090).listen(1024).onConnectionAccepted((TcpListener sender, TcpStream client) {
		debug writefln("new connection from: %s", client.remoteAddress.toString());
		client.onDataReceived((in ubyte[] data) {
			debug writeln("received: ", cast(string) data);
			client.write(data, (in ubyte[] wdata, size_t nBytes) {
				debug writefln("thread: %s, sent bytes: %d, content: %s",
				thisThreadID(), nBytes, cast(string) data[0 .. nBytes]);

				if (data.length > nBytes)
					writefln("remaining bytes: ", data.length - nBytes);
			});

			// client.write(new SocketStreamBuffer(data, (in ubyte[] wdata, size_t size) {
			// 	debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
			// }));
		}).onDisconnected((){
			debug writefln("client disconnected: %s",
			client.remoteAddress.toString());
		}).onClosed(() {
			debug writefln("connection closed, local: %s, remote: %s",
			client.localAddress.toString(),
			client.remoteAddress.toString());
		});
	}).start();

	writeln("Listening on: ", listener.bindingAddress.toString());

	// KissTimer timer = new KissTimer(loop);
	// timer.onTick((Object sender) {
	// 	writeln("The time now is: ", Clock.currTime.toString());
	// }).start(1000);

	loop.run();
}
