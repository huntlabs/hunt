import std.stdio;

import kiss.event;
import kiss.net.TcpListener;
import kiss.net.TcpStream;
import kiss.net.Timer;

import std.socket;
import std.functional;
import std.exception;

void main()
{
	EventLoop loop = new EventLoop();

	TcpListener listener = new TcpListener(loop, AddressFamily.INET);

	listener.bind(0).listen(1024).setReadHandle((EventLoop loop, Socket socket) @trusted nothrow {
				catchAndLogException((){
					TcpStream sock = new TcpStream(loop, socket);

					sock.setReadHandle((in ubyte[] data)@trusted nothrow {
						catchAndLogException((){
							writeln("read Data: ", cast(string)data);

							sock.write(new WarpStreamBuffer(data.dup,(in ubyte[] wdata, size_t size) @trusted nothrow{
									catchAndLogException((){
										writeln("Writed Suessed Size : ", size, "  Data : ", cast(string)wdata);
									}());
								}));
						}());
					}).setCloseHandle(()@trusted nothrow {
						catchAndLogException((){
							writeln("The Socket is Cloesed!");
						}());
					}).watch;
			}());
		}).watch;

	Timer timer = new Timer(loop);
	bool tm = timer.setTimerHandle(()@trusted nothrow {
			catchAndLogException((){
				import std.datetime;
				writeln("The Time is : ", Clock.currTime.toString);
			}());
		}).start(5000);
	writeln("Listen :", listener.bind.toString, "  ", tm);
	loop.join;
}
