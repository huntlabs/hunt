import std.stdio;

import hunt.event.socket;
import hunt.concurrent.thread.Helper;
import hunt.event;
import hunt.io;
import hunt.lang.common;

import std.getopt;
import std.exception;
import hunt.logging;
import std.datetime;
import std.parallelism;

import core.time;
import core.thread;
import std.concurrency;
import std.socket;

__gshared size_t totalSize = 50 * 1024 * 1024 + 1;
__gshared size_t bufferSize = 4096;
__gshared ushort port = 8080;

int totalReceived = 0;
int serverCounter = 0;
int clientCounter = 0;

void main(string[] args)
{
    Tid worker = spawn(&workerFunc);

    GetoptResult o = getopt(args, "port|p", "Port (default 8080)", &port);
    if (o.helpWanted)
    {
        defaultGetoptPrinter("A tcp server for performance test!", o.options);
        return;
    }

    TestTcpServer testServer = new TestTcpServer("0.0.0.0", port, totalCPUs);
    testServer.started = () {
        writefln("All the servers is listening on %s.", testServer.bindingAddress.toString());
        worker.send(1);
    };

    testServer.start();
    worker.send(0);
}

void launchClient()
{
    writeln("launching client.");
    const WatchedValue1 = 1;
    const WatchedValue2 = 23;
    const WatchedValue3 = 4;

    size_t middleIndex = totalSize / 2;
    ubyte[] sendingBuffer = new ubyte[totalSize];
    for(size_t i=0; i<totalSize; i++) 
        sendingBuffer[i] = cast(ubyte)(i % 512);
    // sendingBuffer[0] = WatchedValue1;
    // sendingBuffer[middleIndex] = WatchedValue2;
    // sendingBuffer[$ - 1] = WatchedValue3;

    TcpSocket socket = new TcpSocket();
    socket.blocking = true;
    socket.bind(new InternetAddress("0.0.0.0", 0));
    socket.connect(new InternetAddress("127.0.0.1", port));
    size_t offset = 0;
    for (size_t len = 0; offset < sendingBuffer.length; offset += len)
    {
        len = socket.send(sendingBuffer[offset .. $]);
        debug writefln ("[Client] sending: offset=%d, lenght=%d", offset, len);
    }

    ubyte[] receivedBuffer = new ubyte[totalSize];

    offset = 0;
    for (size_t len; offset < receivedBuffer.length; offset += len)
    {
        len = socket.receive(receivedBuffer[offset .. $]);
        if (len == 0)
            break;

        if (clientCounter % (totalSize / 10 / bufferSize) == 0)
            writefln("[Client] Current=%d, Accumulated=%d", len, offset + len);
        clientCounter++;
    }

    writefln("[Client] received: counter=%d, length=%d, buffer[0]=%d, buffer[$/2]=%d, buffer[$-1]=%d", 
            clientCounter, offset, receivedBuffer[0], receivedBuffer[middleIndex], receivedBuffer[$ - 1]);
    socket.shutdown(SocketShutdown.BOTH);
    socket.close();

    debug writefln("[Client]Peeking received buffer[0 .. 1024]: %(%02X %)", receivedBuffer[0..1024]);
    import std.format;
    for(size_t i=0; i<totalSize; i++) 
        assert(receivedBuffer[i] == cast(ubyte)(i % 512), format("data[%d]=%d, should be: %d", i, 
            receivedBuffer[i], cast(ubyte)(i % 512)));

    // if (receivedBuffer[middleIndex] == WatchedValue2 && receivedBuffer[$ - 1] == WatchedValue3)
        writeln("[Client] test succeeded");
    // else
    //     writefln("[Client] test failed");
}

void workerFunc()
{
    bool isDone = false;
    while (!isDone)
    {
        try
        {
            int m = receiveOnly!int();
            if (m == 1)
            {
                // Thread.sleep(500.msecs);
                launchClient();
                writeln("[Client] done.");
                isDone = true;
            }
            else if (m == 0)
            {
                writeln("[Client] exiting.");
                isDone = true;
            }
        }
        catch (OwnerTerminated exc)
        {
            writeln("The owner has terminated.");
            isDone = true;
        }
        catch (Exception ex)
        {
            writeln("[Client] Exception thrown", ex.message);
            isDone = true;
        }
    }

}

/**
*/
abstract class AbstractTcpServer
{
    protected EventLoopGroup _group = null;
    protected bool _isStarted = false;
    protected Address _address;

    this(Address address, int thread = (totalCPUs - 1))
    {
        this._address = address;
        _group = new EventLoopGroup(cast(uint) thread);
    }

    SimpleEventHandler started;

    @property Address bindingAddress()
    {
        return _address;
    }

    void start()
    {
        if (_isStarted)
            return;
        debug writeln("start to listen");

        for (size_t i = 0; i < _group.size; ++i)
        {
            createServer(_group[i]);
        }
        _group.start();
        _isStarted = true;
        if (started)
            started();
    }

    protected void createServer(EventLoop loop)
    {
        TcpListener listener = new TcpListener(loop, _address.addressFamily, bufferSize);

        listener.reusePort(true);
        listener.bind(_address).listen(1024);
        listener.acceptHandler = &onConnectionAccepted;
        listener.start();
    }

    protected void onConnectionAccepted(TcpListener sender, TcpStream client);

    void stop()
    {
        if (!_isStarted)
            return;
        _isStarted = false;
        _group.stop();
    }
}

/**
*/
class TestTcpServer : AbstractTcpServer
{
    private ubyte[][TcpStream] queue;

    this(string ip, ushort port, int thread = (totalCPUs - 1))
    {
        super(new InternetAddress(ip, port), thread);
    }

    this(Address address, int thread = (totalCPUs - 1))
    {
        super(address, thread);
    }

    override protected void onConnectionAccepted(TcpListener sender, TcpStream client)
    {
        client.onDataReceived((in ubyte[] data) {
            handleReceivedData(client, data);
        }).onClosed(() { onClientClosed(client); }).onError((string msg) {
            writeln("Error on client: ", msg);
        });
    }

    protected void handleReceivedData(TcpStream client, in ubyte[] data)
    {
        queue[client] ~= data;
        ubyte[] buffer = queue[client];

        totalReceived += data.length;
        if (serverCounter % (totalSize / 10 / bufferSize) == 0)
        {
            writefln("[Server] [%d] Received bytes (tid-%d): Current=%d, Accumulated=%d",
                    serverCounter, getTid(), data.length, totalReceived);
        }
        serverCounter++;

        if (buffer.length >= totalSize)
        {
            writefln("[Server] reading done. Counter=%d, Accumulated=%d",
                    serverCounter, buffer.length);
            onRequest(client, buffer);
        }
    }

    private void onRequest(TcpStream client, in ubyte[] data)
    {
        // const(ubyte)[] ret_data = data.idup; // no data copy
        ubyte[] ret_data = data.dup; // no data copy
        size_t sendLength = data.length;

        writefln("[Server] start writing on thread %s, totalSize=%d", getTid(), sendLength);

        client.write(ret_data, (in ubyte[] d, size_t len) {
            writefln("[Server] fininshed writing on thread %s, size=%d", getTid(), len);

            if (sendLength != len)
                writefln("[Server] test failed: shoud=%d actual=%d", sendLength, len);
            else
                writeln("[Server] test succeeded");
        });
    }

    protected void onClientClosed(TcpStream client)
    {
        debug writefln("The connection[%s] is closed on thread %s",
                client.remoteAddress(), getTid());
    }
}