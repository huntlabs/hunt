module kiss.event.loop;

public import kiss.event.base;
import kiss.event.struct_;
import core.thread;
import kiss.event.task;

// 代理模式去实现loop， eventloop的任务队列在此实现。
// 全面采用 前摄器 模式
// 如果加协程，缓存数据放到上层

final @trusted class EventLoop {
    this()
    {
        this(platformLoop());
    }

    this(BaseLoop loop)
    {
        _loop = loop;
    }

    static BaseLoop  platformLoop(){
        return null;
    }

    Watcher createWatcher(WatcherType type){
        return _loop.createWatcher(type);
    }

    bool read(Watcher watcher,scope ReadCallBack read)
    {
        return _loop.read(watcher,read);
    }

    bool write(Watcher watcher,in ubyte[] data, out size_t writed){
        return _loop.write(watcher,data,writed);
    }

    bool register(Watcher watcher){
        return _loop.register(watcher);
    }

    bool reRegister(Watcher watcher){
        return _loop.reRegister(watcher);
    }

    bool unRegister(Watcher watcher){
        return _loop.unRegister(watcher);
    }

    // while(true)
    // todo: 线程安全！
    void join(){
        if(isRuning()){
            throw new LoopException("CURRT EVENT LOOP IS RUNING!");
        }
        _thread = Thread.getThis();
        return _loop.join(&weak);
    }

    void stop(){
        _thread = null;
        return _loop.stop();
    }

    bool isRuning(){
        return (_thread !is null);
    }

    void weakUp(){
        _loop.weakUp();
    }

    void postTask(AbstractTask task){
        synchronized(this){
                _queue.enQueue(task);
            }
    }

    static AbstractTask createTask(alias fun, Args...)(Args args) {
        return newTask!(fun, Args)(args);
    }

    static AbstractTask createTask(F, Args...)(F delegateOrFp, Args args) if (is(typeof(delegateOrFp(args)))) {
        return newTask(F, Args)(delegateOrFp, args);
    }

protected:
    void weak() nothrow
    {
        TaskQueue queue;
        try{
            synchronized(this){
                queue = _queue;
                _queue = TaskQueue();
            }
        } catch(Exception){}
        while(!queue.empty){
            auto task = queue.deQueue();
            task.job();
        }
    }

private:
    Thread _thread;
    BaseLoop _loop;
    TaskQueue _queue;
}