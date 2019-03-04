module hunt.event.selector.Selector;

import hunt.Exceptions;
import hunt.io.channel.AbstractChannel;
import hunt.io.channel.Common;
import hunt.logging.ConsoleLogger;

import core.atomic;

/**
http://tutorials.jenkov.com/java-nio/selectors.html
*/
abstract class Selector {

    protected shared bool _running;
    protected size_t number;
    protected size_t divider;
    protected AbstractChannel[] channels;

    this(size_t number, size_t divider, size_t maxChannels = 1500) {
        this.number = number;
        this.divider = divider;
        channels = new AbstractChannel[maxChannels];
    }

    abstract bool register(AbstractChannel channel);

    abstract bool deregister(AbstractChannel channel);

    void stop() {
        if(cas(&_running, true, false)) {
            version (HUNT_DEBUG)
                trace("Selector stopped.");
        }
    }

    abstract void dispose();

    /**
     * Tells whether or not this selector is open.
     *
     * @return <tt>true</tt> if, and only if, this selector is open
     */
    bool isOpen() {
        return atomicLoad(_running);
    }

    alias isRuning = isOpen;

    /**
        timeout: in millisecond
    */
    protected void onLoop(long timeout = -1) {
        _running = true;
        do {
            // version (HUNT_DEBUG) trace("Selector rolled once.");
            // wakeup();
            doSelect(timeout);
        }
        while (_running);
        version (HUNT_DEBUG) trace("Selector loop existed.");
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

    protected abstract int doSelect(long timeout);

    // private int lockAndDoSelect(long timeout) {
    //     synchronized (this) {
    //     if (!isOpen())
    //         throw new ClosedSelectorException();
    //     synchronized (publicKeys) {
    //         synchronized (publicSelectedKeys) {
    //             return doSelect(timeout);
    //         }
    //     }
    //     return doSelect(timeout);
    //     }
    // }
}