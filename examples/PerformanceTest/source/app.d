import std.stdio;

import hunt.collection.ByteBuffer;
import hunt.concurrency.thread.Helper;
import hunt.event;
import hunt.Functions;
import hunt.io;
import hunt.logging;

import core.time;
import core.thread;

import std.concurrency;
import std.exception;
import std.datetime;
import std.getopt;
import std.parallelism;
import std.socket;

__gshared size_t totalSize = 50 * 1024 * 1024 + 1;  // 50M
// __gshared size_t totalSize = 1024 + 1;
__gshared size_t bufferSize = 4096;
__gshared ushort port = 8080;

int totalReceived = 0;
int serverCounter = 0;
int clientCounter = 0;

void main(string[] args) {
    Tid worker = spawn(&workerFunc);
    // Thread workerThread = new Thread(&workerFunc);

    GetoptResult o = getopt(args, "port|p", "Port (default 8080)", &port);
    if (o.helpWanted) {
        defaultGetoptPrinter("A tcp server for performance test!", o.options);
        return;
    }

    TestTcpServer testServer = new TestTcpServer("0.0.0.0", port, totalCPUs);
    testServer.started = () {
        writefln("All the servers are listening on %s.", testServer.bindingAddress.toString());
        worker.send(1);
        // workerThread.start();
    };

    testServer.start();

    // workerThread.start();
    // worker.send(0);

    thread_joinAll();
}

void launchClient() {
    writeln("[Client] connecting to server...");
    const WatchedValue1 = 1;
    const WatchedValue2 = 23;
    const WatchedValue3 = 4;

    TcpSocket socket = new TcpSocket();
    socket.blocking = true;
    // socket.bind(new InternetAddress("127.0.0.1", 0));
    socket.connect(new InternetAddress("127.0.0.1", port));

    debug writefln("[Client] generating data...");
    size_t middleIndex = totalSize / 2;
    ubyte[] sendingBuffer = new ubyte[totalSize];
    for (size_t i = 0; i < totalSize; i++)
        sendingBuffer[i] = cast(ubyte)(i % 512);
    // sendingBuffer[0] = WatchedValue1;
    // sendingBuffer[middleIndex] = WatchedValue2;
    // sendingBuffer[$ - 1] = WatchedValue3;

    size_t offset = 0;
    size_t step = 1024 * 4;
    for (size_t len = 0; offset < sendingBuffer.length; offset += len) {
        size_t endIndex = offset + step;
        if (endIndex > sendingBuffer.length)
            endIndex = sendingBuffer.length;

        len = socket.send(sendingBuffer[offset .. endIndex]);
        // if(offset % (step*100) == 0) {
        //     debug writefln("[Client] sending: offset=%d, lenght=%d", offset, len);
        // }
    }

    ubyte[] receivedBuffer = new ubyte[totalSize];

    offset = 0;
    for (size_t len; offset < receivedBuffer.length; offset += len) {
        len = socket.receive(receivedBuffer[offset .. $]);
        if (len == 0)
            break;

        size_t n = (totalSize / 10 / bufferSize);
        if (n == 0 || clientCounter % n == 0)
            writefln("[Client] Current=%d, Accumulated=%d", len, offset + len);
        clientCounter++;
    }

    writefln("[Client] received: counter=%d, length=%d, buffer[0]=%d, buffer[$/2]=%d, buffer[$-1]=%d", clientCounter,
            offset, receivedBuffer[0], receivedBuffer[middleIndex], receivedBuffer[$ - 1]);
    socket.shutdown(SocketShutdown.BOTH);
    socket.close();

    debug writefln("[Client]Peeking received buffer[0 .. 1024]: %(%02X %)",
            receivedBuffer[0 .. 1024]);
    import std.format;

    for (size_t i = 0; i < totalSize; i++)
        assert(receivedBuffer[i] == cast(ubyte)(i % 512),
                format("data[%d]=%d, should be: %d", i, receivedBuffer[i], cast(ubyte)(i % 512)));

    // if (receivedBuffer[middleIndex] == WatchedValue2 && receivedBuffer[$ - 1] == WatchedValue3)
    writeln("[Client] test succeeded");
    // else
    //     writefln("[Client] test failed");
}

void workerFunc() {
    bool isDone = false;
    while (!isDone) {
        try {
            int m = receiveOnly!int();
            if (m == 1) {
                Thread.sleep(500.msecs);
                launchClient();
                writeln("[Client] done.");
                isDone = true;
            } else if (m == 0) {
                writeln("[Client] exiting.");
                isDone = true;
            }
        } catch (OwnerTerminated exc) {
            writeln("The owner has terminated.");
            isDone = true;
        } catch (Exception ex) {
            warning("[Client] Exception thrown: ", ex.message);
            isDone = true;
        }
    }

}

/**
*/
abstract class AbstractTcpServer {
    protected EventLoopGroup _group = null;
    protected bool _isStarted = false;
    protected Address _address;

    this(Address address, int thread = (totalCPUs - 1)) {
        this._address = address;
        _group = new EventLoopGroup(cast(uint) thread);
    }

    SimpleEventHandler started;

    @property Address bindingAddress() {
        return _address;
    }

    void start() {
        if (_isStarted)
            return;
        debug writeln("start to listen");

        for (size_t i = 0; i < _group.size; ++i) {
            createServer(_group[i]);
        }
        _group.start();
        _isStarted = true;
        if (started)
            started();
    }

    protected void createServer(EventLoop loop) {
        TcpListener listener = new TcpListener(loop, _address.addressFamily, bufferSize);

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
class TestTcpServer : AbstractTcpServer {
    private ubyte[][TcpStream] queue;

    this(string ip, ushort port, int thread = (totalCPUs - 1)) {
        super(new InternetAddress(ip, port), thread);
    }

    this(Address address, int thread = (totalCPUs - 1)) {
        super(address, thread);
    }

    protected override void onConnectionAccepted(TcpListener sender, TcpStream client) {
        client.onDataReceived((ByteBuffer buffer) {
            handleReceivedData(client, cast(ubyte[]) buffer.getRawData());
        }).onClosed(() { onClientClosed(client); }).onDataWritten((Object obj) {
            writeln("[Server] test succeeded");
        }).onError((string msg) { warning("Error on client: ", msg); });
    }

    protected void handleReceivedData(TcpStream client, in ubyte[] data) {
        queue[client] ~= data;
        ubyte[] buffer = queue[client];

        totalReceived += data.length;
        size_t n = (totalSize / 10 / bufferSize);
        if (n == 0 || serverCounter % (totalSize / 10 / bufferSize) == 0) {
            tracef("[Server] [%d] Received bytes (tid-%d): Current=%d, Accumulated=%d",
                    serverCounter, getTid(), data.length, totalReceived);
        }
        serverCounter++;

        if (buffer.length >= totalSize) {
            tracef("[Server] reading done. Counter=%d, Accumulated=%d",
                    serverCounter, buffer.length);
            onRequest(client, buffer);
        }
    }

    private void onRequest(TcpStream client, in ubyte[] data) {
        // const(ubyte)[] ret_data = data.idup; // no data copy
        ubyte[] ret_data = data.dup; // no data copy
        size_t sendLength = data.length;

        writefln("[Server] start writing on thread %s, totalSize=%d", getTid(), sendLength);
        client.write(ret_data);
    }

    protected void onClientClosed(TcpStream client) {
        debug writefln("The connection[%s] is closed on thread %s",
                client.remoteAddress(), getTid());
    }
}
