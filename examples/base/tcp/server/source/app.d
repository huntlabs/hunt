import std.stdio;

import kiss.event;
import kiss.socket.acceptor;
import kiss.socket.tcp;

import std.socket;
import std.functional;
import std.exception;

void catchException(E)(lazy E runer) @trusted nothrow
{
	try{
		runer();
	} catch (Exception e){
		collectException(writeln(e.toString));
	}
}

void main()
{
	writeln("Edit source/app.d to start your project.");
	EventLoop loop = new EventLoop();

	Acceptor acceptor = new Acceptor(loop, AddressFamily.INET);

	acceptor.bind(parseAddress("0.0.0.0",8081));
	acceptor.listen(1024);

	acceptor.setReadData((EventLoop loop, Socket socket) @trusted nothrow {
		catchException((){
		 	TCPSocket sock = new TCPSocket(loop, socket);

			sock.setReadData((in ubyte[] data)@trusted nothrow {
				catchException((){
					writeln("read Data: ", cast(string)data);

					auto buffer = new WarpTcpBuffer(data.dup,(in ubyte[] wdata, size_t size) @trusted nothrow{
						catchException((){
							writeln("Writed Suessed Size : ", size, "  Data : ", cast(string)wdata);
						}());
					});

					sock.write(buffer);
				}());
			});

			sock.setClose(()@trusted nothrow {
				catchException((){
					writeln("The Socket is Cloesed!");
				}());
			});

			sock.watch;
	 }());
	});

	acceptor.watch;

	loop.join;
}
