module hunt.concurrency.Promise;

import hunt.exception;

/**
 * <p>A callback abstraction that handles completed/failed events of asynchronous operations.</p>
 *
 * @param <C> the type of the context object
 */
interface Promise(C) {

    string id();

    /**
     * <p>Callback invoked when the operation completes.</p>
     *
     * @param result the context
     * @see #failed(Throwable)
     */
    void succeeded(C result);

    /**
     * <p>Callback invoked when the operation fails.</p>
     *
     * @param x the reason for the operation failure
     */
    void failed(Exception x) ;

    /**
     * <p>Empty implementation of {@link Promise}.</p>
     *
     * @param (U) the type of the result
     */
    class Adapter(U) : Promise!U {

        void succeeded(C result){
            
        }
        
        void failed(Throwable x) {

        }
    }
}


class DefaultPromise(C) : Promise!C
{
    string id() { return "default"; }

    void succeeded(C result) {
    }
    
    void failed(Exception x) {
    }
}

