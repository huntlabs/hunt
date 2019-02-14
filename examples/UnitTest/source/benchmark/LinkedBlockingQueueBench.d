module benchmark.LinkedBlockingQueueBench;

import hunt.concurrency.LinkedBlockingQueue;
import hunt.concurrency.BlockingQueue;
import HuntQueue = hunt.collection.Queue;
import hunt.concurrency.MagedQueue;

import hunt.util.DateTime;
import hunt.logging.ConsoleLogger;
import core.thread;
import std.stdio;

void busy_work() {
    // assume compiler is unable to evaluate this at compile time
    import std.random;

    auto gen = Mt19937(11);
    int i = 0;
    foreach (x; gen) {
        i++;
        // writeln(i, "   ", x);
        if (i > 800)
            break;
    }
}

enum MagedMichaelOpCount = 100_000; /* 1_000_000 in paper */
// enum MagedMichaelOpCount = 100; /* 1_000_000 in paper */
enum readers = 6;
enum writers = 10;


void test_run1(HuntQueue.Queue!long q, uint threads) {
    import core.atomic;

    const count = MagedMichaelOpCount / threads;
    Thread[] ts;
    // shared int num = 0;
    foreach (i; 0 .. threads) {
        auto t = new Thread({
            // int n0 = atomicOp!("+=")(num, 1);
            foreach (n; 0 .. count) {
                q.offer(n); 
                // q.offer(n+ n0*100); 
                busy_work();
                auto x = q.poll();
                // tracef("%d", x);
                busy_work();
            }
        });
        t.start();
        ts ~= t;
    }
    foreach (t; ts) {
        t.join();
    }
}

/***
  Benchmark like Maged and Michael.
*/
void test_run2(hunt.concurrency.MagedQueue.Queue!long q, uint threads) {
    const count = MagedMichaelOpCount / threads;
    Thread[] ts;
    foreach (i; 0 .. threads) {
        auto t = new Thread({
            foreach (n; 0 .. count) {
                q.enqueue(n);
                busy_work();
                auto x = q.dequeue();
                busy_work();
            }
        });
        t.start();
        ts ~= t;
    }
    foreach (t; ts) {
        t.join();
    }
}


/**
*/
class LinkedBlockingQueueBench {

    this() {

    }

    void bench() {
        import std.datetime.stopwatch : benchmark;

        LinkedBlockingQueue!(long) lq = new LinkedBlockingQueue!(long)();
        // test_run1(lq, writers);
        // trace(lq.size());

        void f0() { test_run1(lq,            writers); }
        void f2() { test_run2(new MagedBlockingQueue!long(),                writers); }
        void f3() { test_run2(new MagedNonBlockingQueue!long(),             writers); }

        auto r = benchmark!(baseline, f0, f2, f3)(3);
        auto base = r[0];
        writeln(r[1] - base);
        writeln(r[2] - base);
        writeln(r[3] - base);
    }

    void baseline() {
        /* purely the busy work of one thread */
        foreach (_; 0 .. MagedMichaelOpCount / writers) {
            busy_work();
            busy_work();
        }
    }
}



// 1 sec, 836 ms, 867 μs, and 3 hnsecs
// 1 sec, 417 ms, 325 μs, and 9 hnsecs
// 1 sec, 392 ms, 821 μs, and 5 hnsecs
// 1 sec, 412 ms, 656 μs, and 3 hnsecs