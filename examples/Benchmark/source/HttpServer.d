module HttpServer;

version(Windows) :

import std.stdio;

import hunt.event;
import hunt.io;
import hunt.logging;
import hunt.util.timer;
import hunt.util.thread;

import std.array;
import std.conv;
import std.json;
import std.parallelism : totalCPUs;
import std.socket;
import std.string;

import hunt.datetime;


// https://www.techempower.com/benchmarks/

shared static this() {
    DateTimeHelper.startClock();
}

enum ServerThreadMode {
    Single,
    Multi
}

/**
*/
abstract class AbstractTcpServer(ServerThreadMode threadMode = ServerThreadMode.Single) {
	protected EventLoopGroup _group = null;
	protected bool _isStarted = false;
	protected Address _address;
	TcpStreamOption _tcpStreamoption;

	this(Address address, int thread = (totalCPUs - 1)) {
		this._address = address;
		_tcpStreamoption = TcpStreamOption.createOption();
		_group = new EventLoopGroup(cast(uint) thread);
	}

	@property Address bindingAddress() {
		return _address;
	}

	void start() {
		if (_isStarted)
			return;
		debug writeln("start to listen:");
		_group.start();
		static if(threadMode == ServerThreadMode.Multi) {
			for (size_t i = 0; i < _group.size(); ++i) {
				createServer(_group[i]);
				debug writefln("lister[%d] created", i);
			}
			debug writefln("All the servers are listening on %s.", _address.toString());
			_isStarted = true;
		} else {
			debug writeln("Launching server");
			Socket server = new TcpSocket();
			server.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
			server.bind(new InternetAddress("0.0.0.0", 8080));
			server.listen(1000);
			_isStarted = true;

			while(true) {
				try {
					version (HUNT_DEBUG) trace("Waiting for server.accept()");
					Socket client = server.accept();
					// debug writeln("New client accepted");
					processClient(client);
				}
				catch(Exception e) {
					writefln("Failure on accept %s", e);
					break;
				}
			}
			_isStarted = false;	
		}
	}

	private void processClient(Socket socket) {
		version (HUNT_DEBUG) {
			infof("new connection from %s, fd=%d",
				socket.remoteAddress.toString(), socket.handle());
		}
		EventLoop loop = _group.nextLoop();
		TcpStream stream;
		stream = new TcpStream(loop, socket, _tcpStreamoption);
		onConnectionAccepted(null, stream);
		stream.start();
	} 

	protected void createServer(EventLoop loop) {
		TcpListener listener = new TcpListener(loop, _address.addressFamily);

		listener.reusePort(true);
		listener.bind(_address).listen(1024);
		listener.acceptHandler = &onConnectionAccepted;
		listener.start();
	}

	protected void onConnectionAccepted(TcpListener sender, TcpStream client);

	void stop() {
		if (!_isStarted)
			return;
		_isStarted = false;
		_group.stop();
	}
}

/**
*/
class HttpServer : AbstractTcpServer!(ServerThreadMode.Single) {
	this(string ip, ushort port, int thread = (totalCPUs - 1)) {
		super(new InternetAddress(ip, port), thread);
	}

	this(Address address, int thread = (totalCPUs - 1)) {
		super(address, thread);
	}

	override protected void onConnectionAccepted(TcpListener sender, TcpStream client) {
		client.onDataReceived((in ubyte[] data) {
			notifyDataReceived(client, data);
		}).onClosed(() { notifyClientClosed(client); }).onError((string msg) {
			writeln("Error: ", msg);
		});
	}

	protected void notifyDataReceived(TcpStream client, in ubyte[] data) {
		// debug writefln("on thread:%s, data received: %s", getTid(), cast(string) data);
		// string request = cast(string) data;
		bool keepAlive = true; //indexOf(request, " keep-alive", CaseSensitive.no) > 0;

		ptrdiff_t index = 1; // indexOf(request, "/plaintext ", CaseSensitive.no);
		if (index > 0)
			respondPlaintext(client, keepAlive);
		// else if (indexOf(request, "/json ", CaseSensitive.no) > 0) {
		// 	respondJson(client, keepAlive);
		// }
		else {
			badRequest(client);
		}
	}

	private void respondPlaintext(TcpStream client, bool keepAlive) {
        // auto date = cast()atomicLoad(httpDate);
		// string currentTime = Clock.currTime.toString();
		// string currentTime = "Wed, 17 Apr 2013 12:00:00 GMT";
		// string writeData = "HTTP/1.1 200 OK\r\nContent-Length: 13\r\nConnection: Keep-Alive\r\nContent-Type: text/plain\r\nServer: Hunt/1.0\r\nDate: Wed, 17 Apr 2013 12:00:00 GMT\r\n\r\nHello, World!";
		string writeData = "HTTP/1.1 200 OK\r\nContent-Length: 13\r\nConnection: Keep-Alive\r\n" ~ 
			"Content-Type: text/plain\r\nServer: Hunt/1.0\r\nDate: " ~ DateTimeHelper.getDateAsGMT() ~ "\r\n\r\nHello, World!";
        
        // string _body = "Hello, World!";
        // Appender!(char[]) outBuf;
        // outBuf.put("HTTP/1.1 200 OK\r\nConnection: Keep-Alive\r\n");
        // outBuf.put(*date);
        // outBuf.put("Server: Hunt/1.0\r\nContent-Type: text/plain\r\n");
        // formattedWrite(outBuf, "Content-Length: %d\r\n\r\n", _body.length);
        // outBuf.put(_body);
        // writeData = cast(string)outBuf.data;

		client.write(cast(ubyte[]) writeData, (in ubyte[] wdata, size_t size) {
			debug writeln("sent bytes: ", size, "  content: ", writeData);
			if (!keepAlive) {
				debug writefln("closing...%d", client.handle);
				client.close();
			}
		});
	}

	private void respondJson(TcpStream client, bool keepAlive) {
		string currentTime = DateTimeHelper.getDateAsGMT();
		JSONValue js;
		js["message"] = "Hello, World!";
		string content = js.toString();

		string writeData = "HTTP/1.1 200 OK\r\nConnection: Keep-Alive\r\nContent-Type: application/json\r\nContent-Length: " 
			~ to!string(content.length)
			~ "\r\nServer: Hunt/1.0\r\nDate: " ~ currentTime ~ "\r\n\r\n";
		writeData ~= content;
		client.write(cast(ubyte[]) writeData, (in ubyte[] wdata, size_t size) {
			debug writeln("sent bytes: ", size, "  content: ", cast(string) writeData);
			if (!keepAlive)
				client.close();
		});
	}

	private void badRequest(TcpStream client) {
		string writeData = `HTTP/1.1 404 Not Found
Server: Hunt/1.0
Content-Type: text/html
Content-Length: 165
Connection: keep-alive

<html>
<head><title>404 Not Found</title></head>
<body bgcolor="white">
<center><h1>404 Not Found</h1></center>
<hr><center>Hunt/1.0</center>
</body>
</html>
`;

		client.write(cast(ubyte[]) writeData, (in ubyte[] wdata, size_t size) {
			debug info("The connection shutdown now.");
			// import core.thread;
			// import core.time;
			// Thread.sleep(200.msecs);
			client.close();
		});

		// client.close();
	}

	protected void notifyClientClosed(TcpStream client) {
		debug trace("The connection[%s] is closed", client.remoteAddress());
	}
}