module test.MagedQueueTest;

import hunt.concurrency.SimpleQueue;

class MagedQueueTest {

    void testBasic1() {

        NonBlockingQueue!long q = new NonBlockingQueue!long();
        assert(q.isEmpty());
        long v;

        q.enqueue(1);
        assert(q.tryDequeue(v));
        assert(v == 1);
        assert(q.isEmpty());
        assert(!q.tryDequeue(v));

        q.enqueue(1);
        v = q.dequeue();
        assert(v == 1);
        assert(q.isEmpty());

        q.enqueue(1);
        assert(!q.isEmpty());
        q.enqueue(2);

        v = q.dequeue();
        assert(v == 1);
        assert(!q.isEmpty());
        
        v = q.dequeue();
        assert(v == 2);
        assert(q.isEmpty());
    }

    void testSimpleQueue1() {

        SimpleQueue!long q = new SimpleQueue!long();
        assert(q.isEmpty());
        long v;

        q.enqueue(1);
        assert(q.tryDequeue(v));
        assert(v == 1);
        assert(q.isEmpty());
        assert(!q.tryDequeue(v));

        q.enqueue(1);
        v = q.dequeue();
        assert(v == 1);
        assert(q.isEmpty());

        q.enqueue(1);
        assert(!q.isEmpty());
        q.enqueue(2);

        v = q.dequeue();
        assert(v == 1);
        assert(!q.isEmpty());
        
        v = q.dequeue();
        assert(v == 2);
        assert(q.isEmpty());
    }    
}