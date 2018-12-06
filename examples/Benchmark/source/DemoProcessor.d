module DemoProcessor;

import hunt.io;
import http.Processor;

class DemoProcessor : HttpProcessor {
    this(TcpStream sock){ super(sock); }
    
    override void onComplete(HttpRequest req) {
        respondWith("Hello, world!", 200);
    }
}
