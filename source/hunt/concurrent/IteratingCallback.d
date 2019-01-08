module hunt.concurrent.IteratingCallback;

import hunt.util.functional;
import hunt.concurrent.Locker;

import hunt.exception;

import std.format;


/**
 * This specialized callback implements a pattern that allows
 * a large job to be broken into smaller tasks using iteration
 * rather than recursion.
 * <p>
 * A typical example is the write of a large content to a socket,
 * divided in chunks. Chunk C1 is written by thread T1, which
 * also invokes the callback, which writes chunk C2, which invokes
 * the callback again, which writes chunk C3, and so forth.
 * </p>
 * <p>
 * The problem with the example is that if the callback thread
 * is the same that performs the I/O operation, then the process
 * is recursive and may result in a stack overflow.
 * To avoid the stack overflow, a thread dispatch must be performed,
 * causing context switching and cache misses, affecting performance.
 * </p>
 * <p>
 * To avoid this issue, this callback uses an AtomicReference to
 * record whether success callback has been called during the processing
 * of a sub task, and if so then the processing iterates rather than
 * recurring.
 * </p>
 * <p>
 * Subclasses must implement method {@link #process()} where the sub
 * task is executed and a suitable {@link IteratingCallback.Action} is
 * returned to this callback to indicate the overall progress of the job.
 * This callback is passed to the asynchronous execution of each sub
 * task and a call the {@link #succeeded()} on this callback represents
 * the completion of the sub task.
 * </p>
 */
abstract class IteratingCallback : Callback {
    /**
     * The internal states of this callback
     */
    private enum State {
        /**
         * This callback is IDLE, ready to iterate.
         */
        IDLE,

        /**
         * This callback is iterating calls to {@link #process()} and is dealing with
         * the returns.  To get into processing state, it much of held the lock state
         * and set iterating to true.
         */
        PROCESSING,

        /**
         * Waiting for a schedule callback
         */
        PENDING,

        /**
         * Called by a schedule callback
         */
        CALLED,

        /**
         * The overall job has succeeded as indicated by a {@link Action#SUCCEEDED} return
         * from {@link IteratingCallback#process()}
         */
        SUCCEEDED,

        /**
         * The overall job has failed as indicated by a call to {@link IteratingCallback#failed(Exception)}
         */
        FAILED,

        /**
         * This callback has been closed and cannot be reset.
         */
        CLOSED
    }

    /**
     * The indication of the overall progress of the overall job that
     * implementations of {@link #process()} must return.
     */
    protected enum Action {
        /**
         * Indicates that {@link #process()} has no more work to do,
         * but the overall job is not completed yet, probably waiting
         * for additional events to trigger more work.
         */
        IDLE,
        /**
         * Indicates that {@link #process()} is executing asynchronously
         * a sub task, where the execution has started but the callback
         * may have not yet been invoked.
         */
        SCHEDULED,

        /**
         * Indicates that {@link #process()} has completed the overall job.
         */
        SUCCEEDED
    }

    private Locker _locker; // = new Locker();
    private State _state;
    private bool _iterate;


    protected this() {
        _locker = new Locker();
        _state = State.IDLE;
    }

    protected this(bool needReset) {
        _state = needReset ? State.SUCCEEDED : State.IDLE;
    }

    /**
     * Method called by {@link #iterate()} to process the sub task.
     * <p>
     * Implementations must start the asynchronous execution of the sub task
     * (if any) and return an appropriate action:
     * </p>
     * <ul>
     * <li>{@link Action#IDLE} when no sub tasks are available for execution
     * but the overall job is not completed yet</li>
     * <li>{@link Action#SCHEDULED} when the sub task asynchronous execution
     * has been started</li>
     * <li>{@link Action#SUCCEEDED} when the overall job is completed</li>
     * </ul>
     *
     * @return the appropriate Action
     * @throws Exception if the sub task processing throws
     */
    protected abstract Action process();

    /**
     * Invoked when the overall task has completed successfully.
     *
     * @see #onCompleteFailure(Exception)
     */
    protected void onCompleteSuccess() {
    }

    /**
     * Invoked when the overall task has completed with a failure.
     *
     * @param cause the throwable to indicate cause of failure
     * @see #onCompleteSuccess()
     */
    protected void onCompleteFailure(Exception cause) {
    }

    /**
     * This method must be invoked by applications to start the processing
     * of sub tasks.  It can be called at any time by any thread, and it's
     * contract is that when called, then the {@link #process()} method will
     * be called during or soon after, either by the calling thread or by
     * another thread.
     */
    void iterate() {
        bool process = false;
        bool canLoop = true;

        while(canLoop){
                // try {
                    // Locker.Lock lock = _locker.lock();
                    switch (_state) {
                        case State.PENDING:
                        case State.CALLED:
                            // process will be called when callback is handleds
                            canLoop = false;
                            break;

                        case State.IDLE:
                            _state = State.PROCESSING;
                            process = true;
                            canLoop = false;
                            break;

                        case State.PROCESSING:
                            _iterate = true;
                            canLoop = false;
                            break;

                        case State.FAILED:
                        case State.SUCCEEDED:
                            canLoop = false;
                            break;

                        case State.CLOSED:
                        default:
                            canLoop = false;
                            throw new IllegalStateException(toString());
                    }
                // } catch(Exception) {}
            }
            
        if (process)
            processing();
    }

    private void processing() {
        // This should only ever be called when in processing state, however a failed or close call
        // may happen concurrently, so state is not assumed.

        bool on_complete_success = false;

        // While we are processing
        processing:
        while (true) {
            // Call process to get the action that we have to take.
            Action action;
            try {
                action = process();
            } catch (Exception x) {
                failed(x);
                break;
            }

            // acted on the action we have just received
            // try {
                Locker.Lock lock = _locker.lock();
                switch (_state) {
                    case State.PROCESSING: {
                        switch (action) {
                            case Action.IDLE: {
                                // Has iterate been called while we were processing?
                                if (_iterate) {
                                    // yes, so skip idle and keep processing
                                    _iterate = false;
                                    _state = State.PROCESSING;
                                    continue processing;
                                }

                                // No, so we can go idle
                                _state = State.IDLE;
                                break processing;
                            }

                            case Action.SCHEDULED: {
                                // we won the race against the callback, so the callback has to process and we can break processing
                                _state = State.PENDING;
                                break processing;
                            }

                            case Action.SUCCEEDED: {
                                // we lost the race against the callback,
                                _iterate = false;
                                _state = State.SUCCEEDED;
                                on_complete_success = true;
                                break processing;
                            }

                            default:
                                throw new IllegalStateException(format("%s[action=%s]", this, action));
                        }
                    }

                    case State.CALLED: {
                        switch (action) {
                            case Action.SCHEDULED: {
                                // we lost the race, so we have to keep processing
                                _state = State.PROCESSING;
                                continue processing;
                            }

                            default:
                                throw new IllegalStateException(format("%s[action=%s]", this, action));
                        }
                    }

                    case State.SUCCEEDED:
                    case State.FAILED:
                    case State.CLOSED:
                        break processing;

                    case State.IDLE:
                    case State.PENDING:
                    default:
                        throw new IllegalStateException(format("%s[action=%s]", this, action));
                }
            // }catch(Exception) {}
        }

        if (on_complete_success)
            onCompleteSuccess();
    }

    /**
     * Invoked when the sub task succeeds.
     * Subclasses that override this method must always remember to call
     * {@code super.succeeded()}.
     */
    override
    void succeeded() {
        bool process = false;
        // try {
        //     Locker.Lock lock = _locker.lock();
            switch (_state) {
                case State.PROCESSING: {
                    _state = State.CALLED;
                    break;
                }
                case State.PENDING: {
                    _state = State.PROCESSING;
                    process = true;
                    break;
                }
                case State.CLOSED:
                case State.FAILED: {
                    // Too late!
                    break;
                }
                default: {
                    throw new IllegalStateException(toString());
                }
            }
        // }catch(Exception) {}

        if (process)
            processing();
    }

    /**
     * Invoked when the sub task fails.
     * Subclasses that override this method must always remember to call
     * {@code super.failed(Exception)}.
     */
    override
    void failed(Exception x) {
        bool failure = false;
        // try {
        //     Locker.Lock lock = _locker.lock();
            switch (_state) {
                case State.SUCCEEDED:
                case State.FAILED:
                case State.IDLE:
                case State.CLOSED:
                case State.CALLED:
                    // too late!.
                    break;

                case State.PENDING:
                case State.PROCESSING: {
                    _state = State.FAILED;
                    failure = true;
                    break;
                }
                default:
                    throw new IllegalStateException(toString());
            }
        // } catch(Exception) {}

        if (failure)
            onCompleteFailure(x);
    }

    bool isNonBlocking() {
        return false;
    }

    void close() {
        bool failure = false;
        // try {
        //     Locker.Lock lock = _locker.lock();
            switch (_state) {
                case State.IDLE:
                case State.SUCCEEDED:
                case State.FAILED:
                    _state = State.CLOSED;
                    break;

                case State.CLOSED:
                    break;

                default:
                    _state = State.CLOSED;
                    failure = true;
            }
        // }catch(Exception) {}

        if (failure)
            onCompleteFailure(new ClosedChannelException(""));
    }

    /*
     * only for testing
     * @return whether this callback is idle and {@link #iterate()} needs to be called
     */
    bool isIdle() {
        // try {
        //     Locker.Lock lock = _locker.lock();
        //     return _state == State.IDLE;
        // }
        // catch(Exception) {}
        return _state == State.IDLE;
    }

    bool isClosed() {
        // try {
        //     Locker.Lock lock = _locker.lock();
        //     return _state == State.CLOSED;
        // }
        // catch(Exception) {}
        return _state == State.CLOSED;
    }

    /**
     * @return whether this callback has failed
     */
    bool isFailed() {
        // try {
        //     Locker.Lock lock = _locker.lock();
        //     return _state == State.FAILED;
        // }
        // catch(Exception) {}

        return _state == State.FAILED;
    }

    /**
     * @return whether this callback has succeeded
     */
    bool isSucceeded() {
        // try {
        //     Locker.Lock lock = _locker.lock();
        //     return _state == State.SUCCEEDED;
        // }
        // catch(Exception) {}

        return _state == State.SUCCEEDED;
    }

    /**
     * Resets this callback.
     * <p>
     * A callback can only be reset to IDLE from the
     * SUCCEEDED or FAILED states or if it is already IDLE.
     * </p>
     *
     * @return true if the reset was successful
     */
    bool reset() {
        // try {
            // Locker.Lock lock = _locker.lock();
            switch (_state) {
                case State.IDLE:
                    return true;

                case State.SUCCEEDED:
                case State.FAILED:
                    _iterate = false;
                    _state = State.IDLE;
                    return true;

                default:
                    return false;
            }
        // }
        // catch(Exception) {}
    }

    override
    string toString() {
        return format("%s[%s]", super.toString(), _state);
    }
}
