module HttpBenchmarkProcessor;

version (Posix) : 
import http.Processor;
import http.Server;

import std.array, std.exception, std.format, std.algorithm.mutation, std.socket;
import core.stdc.stdlib;
import core.thread, core.atomic;
import http.Parser;
import core.time;

import hunt.datetime;
import hunt.logging;
import hunt.io;

void benchmark(int number = 100) {
    import core.time;
    import std.datetime;
    import hunt.datetime;

    string str = `GET /plaintext HTTP/1.1
cache-control: no-cache
Postman-Token: f290cab4-ac2b-46c7-9db8-ca07f5758989
User-Agent: PostmanRuntime/7.4.0
Accept: */*
Host: 127.0.0.1:8080
accept-encoding: gzip, deflate
Connection: keep-alive

`;
    MonoTime startTime = MonoTime.currTime;
    foreach (j; 0 .. number) {
        HttpBenchmarkProcessor processor = new HttpBenchmarkProcessor();
        processor.handle(str);
    }
    Duration timeElapsed = MonoTime.currTime - startTime;
    size_t t = timeElapsed.total!(TimeUnit.Microsecond)();
    tracef("time consuming (%d), total: %d microseconds, avg: %d microseconds", number, t, t / number);
}

class HttpBenchmarkProcessor {
private:
    enum State {
        url,
        field,
        value,
        done
    }

    ubyte[] buffer;
    Appender!(char[]) outBuf;
    HttpHeader[] headers; // buffer for headers
    size_t header; // current header
    string url; // url
    alias Parser = HttpParser!HttpBenchmarkProcessor;
    Parser parser;
    ScratchPad pad;
    HttpRequest request;
    State state;
    bool serving;
    version (HUNT_METRIC) MonoTime startTime;

public:

    this() {
        serving = true;
        buffer = new ubyte[2048];
        headers = new HttpHeader[1];
        pad = ScratchPad(16 * 1024);
        parser = httpParser(this, HttpParserType.request);
    }

    void handle(string data) {
        parser.execute(data);
    }

    void onComplete(HttpRequest req) {
        switch (req.uri) {
        case "/plaintext":
            respondWith("Hello, World!", 200);
            break;

            // case "/json":
            //     JSONValue js;
            //     js["message"] = "Hello, World!";
            //     string content = js.toString();
            //     respondWith(content, 200, HttpHeader("Content-Type", "application/json"));
            //     break;

        default:
            respondWith("The accessable path are: /plaintext and /json", 404);
            break;
        }
    }
    // void run() {
    // 	client.onDataReceived((const ubyte[] data) {
    // 		version(HUNT_METRIC) {
    // 			debug trace("start hadling session data ...");
    // 			startTime = MonoTime.currTime;
    //         } 
    // 		parser.execute(data);
    // 	})
    // 	.onClosed(() {
    // 		notifyClientClosed();
    // 	})
    // 	.onError((string msg) { warning("Error: ", msg); })
    // 	.start();
    // }

    void respondWith(string _body, uint status, HttpHeader[] headers...) {
        return respondWith(cast(const(ubyte)[]) _body, status, headers);
    }

    void respondWith(const(ubyte)[] _body, uint status, HttpHeader[] headers...) {
        formattedWrite(outBuf, "HTTP/1.1 %s OK\r\n", status);
        outBuf.put("Server: Hunt/1.0\r\n");
        // auto date = Clock.currTime!(ClockType.coarse)(UTC());
        // writeDateHeader(outBuf, date);
        // auto date = cast()atomicLoad(httpDate);

        formattedWrite(outBuf, "Date: %s\r\n", DateTimeHelper.getDateAsGMT());
        if (!parser.shouldKeepAlive)
            outBuf.put("Connection: close\r\n");
        foreach (ref hdr; headers) {
            outBuf.put(hdr.name);
            outBuf.put(": ");
            outBuf.put(hdr.value);
            outBuf.put("\r\n");
        }
        formattedWrite(outBuf, "Content-Length: %d\r\n\r\n", _body.length);
        outBuf.put(cast(string) _body);
        // version(HUNT_METRIC) {
        // 	client.write(cast(ubyte[]) outBuf.data, (const ubyte[] data, size_t size) {
        // 		Duration timeElapsed = MonoTime.currTime - startTime;
        // 		tracef("handling done with cost: %d microseconds",
        // 			timeElapsed.total!(TimeUnit.Microsecond)());
        // 	}); 
        // } else {
        // 	client.write(cast(ubyte[]) outBuf.data); // TODO: short-writes are quite possible
        // }
    }

    void onStart(HttpRequest req) {
    }

    void onChunk(HttpRequest req, const(ubyte)[] chunk) {
    }

    void onComplete(HttpRequest req);

    //privatish stuff
    final int onMessageBegin(Parser* parser) {
        outBuf.clear();
        header = 0;
        pad.reset();
        state = State.url;
        return 0;
    }

    final int onUrl(Parser* parser, const(ubyte)[] chunk) {
        pad.put(chunk);
        return 0;
    }

    final int onBody(Parser* parser, const(ubyte)[] chunk) {
        onChunk(request, chunk);
        return 0;
    }

    final int onHeaderField(Parser* parser, const(ubyte)[] chunk) {
        final switch (state) {
        case State.url:
            url = pad.sliceStr;
            break;
        case State.value:
            headers[header].value = pad.sliceStr;
            header += 1;
            if (headers.length <= header)
                headers.length += 1;
            break;
        case State.field:
        case State.done:
            break;
        }
        state = State.field;
        pad.put(chunk);
        return 0;
    }

    final int onHeaderValue(Parser* parser, const(ubyte)[] chunk) {
        if (state == State.field) {
            headers[header].name = pad.sliceStr;
        }
        pad.put(chunk);
        state = State.value;
        return 0;
    }

    final int onHeadersComplete(Parser* parser) {
        headers[header].value = pad.sliceStr;
        header += 1;
        request = HttpRequest(headers[0 .. header], parser.method, url);
        onStart(request);
        state = State.done;
        return 0;
    }

    final int onMessageComplete(Parser* parser) {
        import std.stdio;

        if (state == State.done)
            onComplete(request);
        if (!parser.shouldKeepAlive)
            serving = false;
        return 0;
    }

}

// ==================================== IMPLEMENTATION DETAILS ==============================================
private:

struct ScratchPad {
    ubyte* ptr;
    size_t capacity;
    size_t last, current;

    this(size_t size) {
        ptr = cast(ubyte*) malloc(size);
        capacity = size;
    }

    void put(const(ubyte)[] slice) {
        enforce(current + slice.length <= capacity, "HTTP headers too long");
        ptr[current .. current + slice.length] = slice[];
        current += slice.length;
    }

    const(ubyte)[] slice() {
        auto data = ptr[last .. current];
        last = current;
        return data;
    }

    string sliceStr() {
        return cast(string) slice;
    }

    void reset() {
        current = 0;
        last = 0;
    }

    @disable this(this);

    ~this() {
        free(ptr);
        ptr = null;
    }
}
