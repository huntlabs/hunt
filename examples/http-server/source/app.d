import std.stdio;

import kiss.event;
import kiss.net.TcpListener;
import kiss.net.TcpStream;
import kiss.net.Timer;

import std.socket;
import std.functional;
import std.exception;
import std.experimental.logger;
import std.experimental.logger.filelogger;

void main()
{
	EventLoop loop = new EventLoop();

	TcpListener listener = new TcpListener(loop, AddressFamily.INET);

	// sharedLog = new FileLogger("log.txt");
	listener.reusePort(true);
	listener.bind(10001).listen(1024).setReadHandle((EventLoop loop, Socket socket) @trusted nothrow{
		catchAndLogException(() {
			TcpStream sock = new TcpStream(loop, socket);

			sock.setReadHandle((in ubyte[] data) @trusted nothrow{
				catchAndLogException(() {
					writeln("read data: ", cast(string) data);
					string writeData = "HTTP/1.1 200 OK\r\nContent-Length: 13\r\nConnection: Keep-Alive\r\nContent-Type: text/plain\r\nServer: Kiss\r\nDate: Wed, 17 Apr 2013 12:00:00 GMT\r\n\r\nHello, World!";
					sock.write(new WarpStreamBuffer(cast(ubyte[]) writeData,
					(in ubyte[] wdata, size_t size) @trusted nothrow{
						catchAndLogException(() {
							writeln("written size: ", size, "  Data: ", cast(string) wdata);
							sock.close();
						}());
					}));
				}());
			}).setCloseHandle(() @trusted nothrow{
				catchAndLogException(() { writeln("The Socket is Cloesed!"); }());
			}).watch;
		}());
	}).watch;

	writeln("The server is listening on 10001.");
	loop.join;
}
