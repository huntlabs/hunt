import std.stdio;

import kiss.event;
import kiss.net.TcpListener;
import kiss.net.TcpStream;
import kiss.net.Timer;

import std.socket;
import std.functional;
import std.exception;
import std.experimental.logger;

void main()
{
	EventLoop loop = new EventLoop();
	TcpListener listener = new TcpListener(loop, AddressFamily.INET);

	listener.bind(8096).listen(1024).setReadHandle((EventLoop loop, Socket socket) @trusted nothrow {
				catchAndLogException((){
					debug trace("A new connection comes from ", socket.remoteAddress.toString());
					TcpStream sock = new TcpStream(loop, socket);
					sock.setReadHandle((in ubyte[] data)@trusted nothrow {
						catchAndLogException((){
							debug writeln("received: ", cast(string)data);
							sock.write(new WarpStreamBuffer(data.dup,(in ubyte[] wdata, size_t size) @trusted nothrow{
									catchAndLogException((){
										debug writeln("sent: size=", size, "  content: ", cast(string)wdata);
									}());
								}));
						}());
					}).setCloseHandle(()@trusted nothrow {
						catchAndLogException((){
							writeln("The connection has been shutdown!");
						}());
					}).watch;
			}());
		}).watch;

	// Timer timer = new Timer(loop);
	// bool tm = timer.setTimerHandle(()@trusted nothrow {
	// 		catchAndLogException((){
	// 			import std.datetime;
	// 			writeln("The Time is : ", Clock.currTime.toString);
	// 		}());
	// 	}).start(1000);
	writeln("Listen :", listener.bind.toString, "  ");
	loop.join;
}
