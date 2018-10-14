module test.LinkedBlockingQueueTest;

import hunt.concurrent.LinkedBlockingQueue;
import hunt.datetime;
import hunt.logging.ConsoleLogger;
import hunt.util.exception;

import core.thread;
import core.time;
import std.stdio;

/**
https://www.concretepage.com/java/linkedblockingqueue_java
*/
class LinkedBlockingQueueTest {
    private LinkedBlockingQueue!string lbqueue;

    this() {
        lbqueue = new LinkedBlockingQueue!string();
    }

    void offerThread() {
        
        ConsoleLogger.trace("start producting...");
        lbqueue.offer("AAAA");
        lbqueue.offer("BBBB");
        ConsoleLogger.trace("wait for producting...");
        Thread.sleep(dur!(cast(string)TimeUnit.Second)(3));
        lbqueue.offer("CCCC");
        lbqueue.offer("DDDD");
        lbqueue.offer("EEEE");
        ConsoleLogger.trace("producting done.");
    }

    void takeThread() {
        try {
            ConsoleLogger.trace("start taking...");
            for (int i = 0; i < 5; i++) {
                writeln(lbqueue.take());
            }
            ConsoleLogger.trace("taking done!");
        }
        catch (InterruptedException e) {
            ConsoleLogger.warning(e.toString());
        }
    }

    void testBasicOperation() {
        LinkedBlockingQueue!int queue1 = new LinkedBlockingQueue!int();
        const int Number = 5000;
        for(int i=0; i<Number; i++) {
            queue1.add(i);
        }
        assert(Number == queue1.size());

        // 
        LinkedBlockingQueue!int queue2 = new LinkedBlockingQueue!int();
        assert("[]" == queue2.toString());
        
        const int Number2 = 5;
        for(int i=1; i<=Number2; i++)
            queue2.put(10*i);

        assert(Number2 == queue2.size());
        assert("[10, 20, 30, 40, 50]" == queue2.toString());

        // 
        LinkedBlockingQueue!int queue3 = new LinkedBlockingQueue!int(queue2);
        assert(queue3.size() == queue2.size());
        
        LinkedBlockingQueue!int queue4 = new LinkedBlockingQueue!int();
        for(int i=1; i<=2; i++) {
            queue4.put(queue3.poll());
        }
        assert(queue4.toString() == "[10, 20]");
        assert(queue3.size() + queue4.size() == queue2.size());

        queue1.clear();
        assert(0 == queue1.size());

    }
    
    void testOffer() {

        Thread threadA = new Thread(&offerThread);
        Thread threadB = new Thread(&takeThread);
        threadA.start();
        threadB.start();

        thread_joinAll();
    }
}
