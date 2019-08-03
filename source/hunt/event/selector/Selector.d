module hunt.event.selector.Selector;

import hunt.Exceptions;
import hunt.Functions;
import hunt.io.channel.AbstractChannel;
import hunt.io.channel.Common;
import hunt.logging.ConsoleLogger;

import core.atomic;
import core.thread;


/**
http://tutorials.jenkov.com/java-nio/selectors.html
*/
abstract class Selector {

    private shared bool _running;
    protected size_t number;
    protected size_t divider;
    protected AbstractChannel[] channels;
    protected long idleTime = -1; // in millisecond
    protected int fd;

    private long timeout = -1; // in millisecond
    private Thread _thread;

    private SimpleEventHandler _startedHandler;
    private SimpleEventHandler _stoppeddHandler;

    this(size_t number, size_t divider, size_t maxChannels = 1500) {
        this.number = number;
        this.divider = divider;
        channels = new AbstractChannel[maxChannels];
    }

    abstract bool register(AbstractChannel channel);

    abstract bool deregister(AbstractChannel channel);

    protected abstract int doSelect(long timeout);


    void onStarted(SimpleEventHandler handler) {
        this._startedHandler = handler;
    }

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
    void runAsync(long timeout = -1) {
        this.timeout = timeout;
        version (HUNT_IO_DEBUG) trace("runAsync ...");
        Thread th = new Thread(&doRun);
        // th.isDaemon = true; // unstable
        th.start();
    }
    
    private void doRun() {
        if(cas(&_running, false, true)) {
            version (HUNT_IO_DEBUG) trace("running selector...");
            _thread = Thread.getThis();
            if(_startedHandler !is null) {
                _startedHandler();
            }
            onLoop(timeout);
        } else {
            version (HUNT_DEBUG) warning("The current selector is running!");
        }  
    }

    void stop() {
        version (HUNT_IO_DEBUG)
            tracef("Selector stopping. _running=%s", _running); 
        if(cas(&_running, true, false)) {
            // version (HUNT_IO_DEBUG)
            //     tracef("Selector stopping. idleTime=%d", idleTime);            
            // dispose();
            onStop();
        }
    }

    protected void onStop() {
        version (HUNT_IO_DEBUG) 
            tracef("stopping.");
        // _thread = null;
    }

    /**
     * Tells whether or not this selector is open.
     *
     * @return <tt>true</tt> if, and only if, this selector is open
     */
    bool isOpen() {
        return _running;
    }

    alias isRuning = isOpen;

    /**
        timeout: in millisecond
    */
    protected void onLoop(long timeout = -1) {
        // _running = true;
        idleTime = timeout;
        do {
            // wakeup();
            doSelect(timeout);
            // infof("Selector rolled once. isRuning: %s", isRuning);
        }
        while (_running);
        version(HUNT_DEBUG) info("Selector loop existed.");
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