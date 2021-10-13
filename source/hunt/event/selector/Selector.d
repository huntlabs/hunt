module hunt.event.selector.Selector;

import hunt.Exceptions;
import hunt.Functions;
import hunt.io.channel.AbstractChannel;
import hunt.io.channel.Common;
import hunt.logging.ConsoleLogger;
import hunt.util.worker;

import core.atomic;
import core.memory;
import core.thread;


/**
http://tutorials.jenkov.com/java-nio/selectors.html
*/
abstract class Selector {

    private shared bool _running = false;
    private shared bool _isStopping = false;
    private bool _isReady;
    protected size_t _id;
    protected size_t divider;
    private Worker _taskWorker;
    // protected AbstractChannel[] channels;
    protected long idleTime = -1; // in millisecond
    protected int fd;

    private long timeout = -1; // in millisecond
    private Thread _thread;

    private SimpleEventHandler _startedHandler;
    private SimpleEventHandler _stoppeddHandler;

    this(size_t id, size_t divider, Worker worker = null, size_t maxChannels = 1500) {
        _id = id;
        _taskWorker = worker;
        this.divider = divider;
        // channels = new AbstractChannel[maxChannels];
    }

    size_t getId() {
        return _id;
    }

    Worker worker() {
        return _taskWorker;
    }

    bool isReady() {
        return _isReady;
    }


    /**
     * Tells whether or not this selector is running.
     *
     * @return <tt>true</tt> if, and only if, this selector is running
     */
    bool isRuning() {
        return _running;
    }

    alias isOpen = isRuning;

    bool isStopping() {
        return _isStopping;
    }

    bool register(AbstractChannel channel) {
        assert(channel !is null);
        channel.taskWorker = _taskWorker;
        void* context = cast(void*)channel;
        GC.addRoot(context);
        GC.setAttr(cast(void*)context, GC.BlkAttr.NO_MOVE);
        version (HUNT_IO_DEBUG) {
            int infd = cast(int) channel.handle;
            infof("Register channel@%s: fd=%d, selector: %d", context, infd, getId());
        }        
        return true;
    }

    bool deregister(AbstractChannel channel) {
        channel.taskWorker = null;
        void* context = cast(void*)channel;
        GC.removeRoot(context);
        GC.clrAttr(context, GC.BlkAttr.NO_MOVE);
        version(HUNT_IO_DEBUG) {
            size_t fd = cast(size_t) channel.handle;
            infof("The channel@%s has been deregistered: fd=%d, selector: %d", context, fd, getId());
        }        
        return true;
    }

    protected abstract int doSelect(long timeout);

    /**
        timeout: in millisecond
    */
    void run(long timeout = -1) {
        this.timeout = timeout;
        doRun();
    }

    /**
        timeout: in millisecond
    */
    void runAsync(long timeout = -1, SimpleEventHandler handler = null) {
        if(_running) {
            version (HUNT_IO_DEBUG) warningf("The current selector %d has being running already!", _id);
            return;
        }

        this.timeout = timeout;
        version (HUNT_IO_DEBUG) tracef("runAsync ... Thread: %d", Thread.getAll().length);
        
        _workThread = new Thread(() { 
            try {
                doRun(handler); 
            } catch (Throwable t) {
                warning(t.msg);
                version(HUNT_DEBUG) warning(t.toString());
            }
        });
        // th.isDaemon = true; // unstable
        _workThread.start();

        // BUG: Reported defects -@zhangxueping at 2021-10-12T18:25:30+08:00
        // https://issues.dlang.org/show_bug.cgi?id=22346
        // import std.parallelism;

        // auto workerTask = task(() { 
        //     try {
        //         doRun(handler); 
        //     } catch (Throwable t) {
        //         warning(t.msg);
        //         version(HUNT_DEBUG) warning(t.toString());
        //     }
        // });
        
        // taskPool.put(workerTask);
    }

    private Thread _workThread;

    
    private void doRun(SimpleEventHandler handler=null) {
        if(cas(&_running, false, true)) {
            version (HUNT_IO_DEBUG) trace("running selector...");
            _thread = Thread.getThis();
            if(handler !is null) {
                handler();
            }
            onLoop(timeout);
        } else {
            version (HUNT_DEBUG) warningf("The current selector %d has being running already!", _id);
        }  
    }

    void stop() {
        version (HUNT_IO_DEBUG)
            tracef("Stopping selector %d. _running=%s, _isStopping=%s", _id, _running, _isStopping); 
        
        if(cas(&_isStopping, false, true)) {
            try {
                onStop();
            } catch(Throwable t) {
                warning(t.msg);
                version(HUNT_DEBUG) warning(t);
            }

            if(_workThread !is null)
                _workThread.join;
        }
    }

    protected void onStop() {
        version (HUNT_IO_DEBUG) 
            tracef("stopping.");
    }

    /**
        timeout: in millisecond
    */
    protected void onLoop(long timeout = -1) {
        _isReady = true;
        idleTime = timeout;

        version (HAVE_IOCP) {
            doSelect(timeout);
        } else {
            do {
                // version(HUNT_THREAD_DEBUG) warningf("Threads: %d", Thread.getAll().length);
                doSelect(timeout);
                // infof("Selector rolled once. isRuning: %s", isRuning);
            } while (!_isStopping);
        }

        _isReady = false;
        _running = false;
        version(HUNT_IO_DEBUG) infof("Selector %d exited.", _id);
        dispose();
    }

    /**
        timeout: in millisecond
    */
    int select(long timeout) {
        if (timeout < 0)
            throw new IllegalArgumentException("Negative timeout");
        return doSelect((timeout == 0) ? -1 : timeout);
    }

    int select() {
        return doSelect(0);
    }

    int selectNow() {
        return doSelect(0);
    }

    void dispose() {
        _thread = null;
        _startedHandler = null;
        _stoppeddHandler = null;
    }
    
    bool isSelfThread() {
        return _thread is Thread.getThis();
    }

    override string toString() {
        import std.format;
        string str = format("Selector%d", this.getId());

        return str;
    }    
}
