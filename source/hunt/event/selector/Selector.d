module hunt.event.selector.Selector;

import hunt.Exceptions;
import hunt.Functions;
import hunt.io.channel.AbstractChannel;
import hunt.io.channel.Common;
import hunt.logging.ConsoleLogger;

import core.atomic;
import core.thread;
import hunt.collection.ByteBuffer;
import hunt.collection.BufferUtils;

/**
http://tutorials.jenkov.com/java-nio/selectors.html
*/

struct ReadBuffer
{
    bool isUsed = false;
    ByteBuffer buffer = null;
}

abstract class Selector {

    private shared bool _running = false;
    private shared bool _isStopping = false;
    private bool _isReady;
    protected size_t number;
    protected size_t divider;
    protected AbstractChannel[] channels;
    protected long idleTime = -1; // in millisecond
    protected int fd;

    private size_t _eachBufferSize;
    protected int readBufferSize = 2000;
    protected ReadBuffer[] readBufferArray;

    private long timeout = -1; // in millisecond
    private Thread _thread;

    private SimpleEventHandler _startedHandler;
    private SimpleEventHandler _stoppeddHandler;

    this(size_t number, size_t divider, size_t maxChannels = 1500) {
        this.number = number;
        this.divider = divider;
        channels = new AbstractChannel[maxChannels];
    }

    private void InitReadBufferArray(size_t eachBufferSize)
    {
        readBufferArray = new ReadBuffer[readBufferSize];
        for(int i = 0 ; i < readBufferSize ; ++ i)
        {
              ReadBuffer rdBuffer;
              rdBuffer.buffer = BufferUtils.allocate(eachBufferSize);
              readBufferArray[i] = rdBuffer;
        }
    }

    ByteBuffer getReadBuffer(ref int index)
    {
        foreach( i ; 0 .. readBufferSize)
        {
          if(!readBufferArray[i].isUsed)
          {
              readBufferArray[i].isUsed = true;
              index = i;
              return readBufferArray[i].buffer;
          }
        }
        ReadBuffer newBuffer;
        newBuffer.isUsed = true;
        newBuffer.buffer = BufferUtils.allocate(_eachBufferSize);
        readBufferArray ~= newBuffer;
        index = readBufferSize;
        readBufferSize += 1;
        return newBuffer.buffer;
    }

    void putReadBuffer(int index)
    {
        readBufferArray[index].isUsed = false;
        readBufferArray[index].buffer.rewind;
    }

    size_t getId() {
        return number;
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


    abstract bool register(AbstractChannel channel);

    abstract bool deregister(AbstractChannel channel);

    bool update(AbstractChannel channel) { return true; }

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
    void runAsync(size_t readBufferSize ,long timeout = -1, SimpleEventHandler handler = null ) {
        if(_running) {
            version (HUNT_IO_DEBUG) warningf("The current selector %d has being running already!", number);
            return;
        }
        this.timeout = timeout;
        InitReadBufferArray(readBufferSize);
        version (HUNT_IO_DEBUG) trace("runAsync ...");
        Thread th = new Thread(() {
            try {
                doRun(handler);
            } catch (Throwable t) {
                warning(t.msg);
                version(HUNT_DEBUG) warning(t.toString());
            }
        });
        // th.isDaemon = true; // unstable
        th.start();
    }

    private void doRun(SimpleEventHandler handler=null) {
        if(cas(&_running, false, true)) {
            version (HUNT_IO_DEBUG) trace("running selector...");
            _thread = Thread.getThis();
            if(handler !is null) {
                handler();
            }
            onLoop(timeout);
        } else {
            version (HUNT_DEBUG) warningf("The current selector %d has being running already!", number);
        }
    }

    void stop() {
        version (HUNT_IO_DEBUG)
            tracef("Stopping selector %d. _running=%s, _isStopping=%s", number, _running, _isStopping);
        if(cas(&_isStopping, false, true)) {
            try {
                onStop();
            } catch(Throwable t) {
                warning(t.msg);
                version(HUNT_DEBUG) warning(t);
            }
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
        do {
            // wakeup();
            doSelect(timeout);
            // infof("Selector rolled once. isRuning: %s", isRuning);
        }
        while (!_isStopping);
        _isReady = false;
        _running = false;
        version(HUNT_DEBUG_MORE) infof("Selector %d existed.", number);
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
}
