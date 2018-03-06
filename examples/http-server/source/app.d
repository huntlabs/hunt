import std.stdio;

import kiss.event;
import kiss.net.TcpListener;
import kiss.net.TcpStream;
import kiss.net.Timer;

import std.socket;
import std.functional;
import std.getopt;
import std.exception;
import std.experimental.logger;
import std.experimental.logger.filelogger;

void main(string[] args)
{
	globalLogLevel(LogLevel.warning);
	
	ushort port = 8080;
	GetoptResult o = getopt(args,"port|p","端口(默认8080)",&port);
	if (o.helpWanted){
		defaultGetoptPrinter("A simple demo for http server!",
			o.options);
		return;
	}

	EventLoop loop = new EventLoop();
	TcpListener listener = new TcpListener(loop, AddressFamily.INET);

	// sharedLog = new FileLogger("log.txt");
	listener.reusePort(true);
	listener.bind(port).listen(1024).setReadHandle((EventLoop loop, Socket socket) @trusted nothrow{
		catchAndLogException(() {
			TcpStream sock = new TcpStream(loop, socket);

			sock.setReadHandle((in ubyte[] data) @trusted nothrow{
				catchAndLogException(() {
					debug writeln("read data: ", cast(string) data);
					string writeData = "HTTP/1.1 200 OK\r\nContent-Length: 13\r\nConnection: Keep-Alive\r\nContent-Type: text/plain\r\nServer: Kiss\r\nDate: Wed, 17 Apr 2013 12:00:00 GMT\r\n\r\nHello, World!";
					sock.write(new WarpStreamBuffer(cast(ubyte[]) writeData,
					(in ubyte[] wdata, size_t size) @trusted nothrow{
						catchAndLogException(() {
							debug writeln("written size: ", size, "  Data: ", cast(string) wdata);
							sock.close();
						}());
					}));
				}());
			}).setCloseHandle(() @trusted nothrow{
				debug catchAndLogException(() { writeln("The Socket is Cloesed!"); }());
			}).watch;
		}());
	}).watch;

	writefln("The server is listening on %s.", listener.localAddress.toString());
	loop.join;
}
