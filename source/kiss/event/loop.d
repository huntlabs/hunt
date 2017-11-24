module kiss.event.loop;

public import kiss.event.base;
import core.thread;

// 代理模式去实现loop， eventloop的任务队列在此实现。
// 全面采用 前摄器 模式
// 如果加协程，缓存数据放到上层

final class EventLoop {
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

    void read(Watcher watcher,scope ReadCallBack read)
    {
        return _loop.read(watcher,read);
    }

    bool write(Watcher watcher,in ubyte[] data, out size_t writed){
        return _loop.write(watcher,data,writed);
    }

    // 关闭会自动unRegister的
    bool close(Watcher watcher){
        return _loop.close(watcher);
    }

    bool register(Watcher watcher){
        return _loop.register(watcher);
    }

    bool unRegister(Watcher watcher){
        return _loop.unRegister(watcher);
    }

    // while(true)
    void join(){
        _thread = Thread.getThis();
        return _loop.join(&weak);
    }

    void stop(){
        _thread = null;
        return _loop.stop();
    }

    void weakUp(){
        _loop.weakUp();
    }

    void postTask(){}

protected:
    void weak() nothrow
    {}

private:
    Thread _thread;
    BaseLoop _loop;
}