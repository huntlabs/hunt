module DemoProcessor;

version(Posix):

import hunt.io;
import http.Processor;

class DemoProcessor : HttpProcessor {
    this(TcpStream client){ super(client); }
    
    override void onComplete(HttpRequest req) {
        respondWith("Hello, World!", 200);
    }
}
