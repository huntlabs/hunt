module test.TaskPoolTest;

import hunt.concurrency.TaskPool;
import hunt.logging.ConsoleLogger;
import hunt.concurrency.SimpleQueue;
import hunt.system.Memory;
import hunt.util.Common;

import std.format;
import std.random;

import core.atomic;
import core.thread;
import core.time;


class TaskPoolTest {

    void testBasic() {
        enum count = 30;
        enum nthread = 5;
        TaskPool taskPool = new TaskPool(5);

        // taskPool.put(new Task!(doSomething, string)("test01"));
        taskPool.put(0, makeTask!(doSomething)("task00"));

        // foreach(i; 0..30) {
        //     taskPool.put(makeTask(&doTask, format("task%02d", i)));
        // }

        shared int num = 0;
        foreach(i; 0..nthread) {
            Thread t = new Thread((){
                int n = atomicOp!("+=")(num, 1) - 1;
                infof("n=%d", n);
                int len = count/nthread;
                int start = n * len;
                for(int j=start; j<start+len; j++) {
                    taskPool.put(j, makeTask(&doTask, format("task%02d", j)));
                }
            });
            t.start();
        }

    }

    static void doSomething(string name) {
        trace("do something with function for " ~ name);
        Thread.sleep(dur!("msecs")(300));
        tracef("%s done. ", name);
    }

    void doTask(string name) {
        trace("do something with delegate for " ~ name);
        Thread.sleep(dur!("msecs")(uniform(200, 300)));
        tracef("%s done. ", name);
    }
}
