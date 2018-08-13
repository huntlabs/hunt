module hunt.util.LifeCycle;

interface LifeCycle {
    
	void start();

	void stop();

	bool isStarted();

	bool isStopped();
}


abstract class AbstractLifeCycle : LifeCycle {

    // protected static final List<Action0> stopActions = new CopyOnWriteArrayList<>();

    // static {
    //     try {
    //         Runtime.getRuntime().addShutdownHook(new Thread(() -> {
    //             stopActions.forEach(a -> {
    //                 try {
    //                     a.call();
    //                 } catch (Exception e) {
    //                     System.err.println(e.getMessage());
    //                 }
    //             });
    //             System.out.println("Shutdown instance: " + stopActions.size());
    //             stopActions.clear();
    //         }, "the firefly shutdown thread"));
    //     } catch (Exception e) {
    //         System.err.println(e.getMessage());
    //     }
    // }

    protected bool _isStarted;

    this() {
        // stopActions.add(this::stop);
    }

    override
    bool isStarted() {
        return _isStarted;
    }

    override
    bool isStopped() {
        return !_isStarted;
    }

    override
    void start() {
        if (isStarted())
            return;

        synchronized (this) {
            if (isStarted())
                return;

            init();
            _isStarted = true;
        }
    }

    override
    void stop() {
        if (isStopped())
            return;

        synchronized (this) {
            if (isStopped())
                return;

            destroy();
            _isStarted = false;
        }
    }

    abstract protected void init();

    abstract protected void destroy();

}