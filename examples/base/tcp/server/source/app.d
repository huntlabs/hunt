import std.stdio;

import kiss.event;
import kiss.socket.acceptor;
import kiss.socket.tcp;

import std.socket;
import std.functional;
import std.exception;

void main()
{
	writeln("Listen Port: 8081");
	EventLoop loop = new EventLoop();

	Acceptor acceptor = new Acceptor(loop, AddressFamily.INET);

	acceptor.bind(parseAddress("0.0.0.0",8081)).listen(1024).setReadData((EventLoop loop, Socket socket) @trusted nothrow {
				catchAndLogException((){
					TCPSocket sock = new TCPSocket(loop, socket);

					sock.setReadData((in ubyte[] data)@trusted nothrow {
						catchAndLogException((){
							writeln("read Data: ", cast(string)data);

							sock.write(new WarpTcpBuffer(data.dup,(in ubyte[] wdata, size_t size) @trusted nothrow{
									catchAndLogException((){
										writeln("Writed Suessed Size : ", size, "  Data : ", cast(string)wdata);
									}());
								}));
						}());
					}).setClose(()@trusted nothrow {
						catchAndLogException((){
							writeln("The Socket is Cloesed!");
						}());
					}).watch;
			}());
		}).watch;

	loop.join;
}
