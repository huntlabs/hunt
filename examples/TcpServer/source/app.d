import std.stdio;

import kiss.event;
import kiss.net.TcpListener;
import kiss.net.TcpStream;
import kiss.util.KissTimer;
import kiss.util.thread;

import std.socket;
import std.functional;
import std.exception;
import std.datetime;
import std.experimental.logger;
import std.process;

void main()
{
	debug writefln("Main thread: %s", getTid());
	globalLogLevel(LogLevel.warning);

	// to test big block data sending
	int bufferSize = 8192 * 2 + 1;
	ubyte[] bigData = new ubyte[bufferSize];
	bigData[0] = 1;
	bigData[$ - 1] = 2;

	EventLoop loop = new EventLoop();
	TcpListener listener = new TcpListener(loop, AddressFamily.INET, 512);

	listener.bind(8090).listen(1024).onConnectionAccepted((TcpListener sender, TcpStream client) {
		debug writefln("new connection from: %s", client.remoteAddress.toString());
		client.onDataReceived((in ubyte[] data) {
			debug writeln("received bytes: ", data.length);
			// debug writefln("received: %(%02X %)", data);
			// const(ubyte)[] sentData = bigData;	// big data test
			const(ubyte)[] sentData = data; // echo test
			client.write(sentData, (in ubyte[] wdata, size_t nBytes) {
				debug writefln("thread: %s, sent bytes: %d", getTid(), nBytes);

				if (sentData.length > nBytes)
					writefln("remaining bytes: ", sentData.length - nBytes);
			});

			// client.write(new SocketStreamBuffer(data, (in ubyte[] wdata, size_t size) {
			// 	debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
			// }));
		}).onDisconnected(() {
			debug writefln("client disconnected: %s", client.remoteAddress.toString());
		}).onClosed(() {
			debug writefln("connection closed, local: %s, remote: %s",
			client.localAddress.toString(), client.remoteAddress.toString());
		});
	}).start();

	writeln("Listening on: ", listener.bindingAddress.toString());

	// KissTimer timer = new KissTimer(loop);
	// timer.onTick((Object sender) {
	// 	writeln("The time now is: ", Clock.currTime.toString());
	// }).start(1000);

	loop.run();
}
