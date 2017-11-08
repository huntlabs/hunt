module kiss.event.base;

alias ReadCallBack = void delegate(in ubyte[] data) nothrow;

enum WatcherType : ubyte
{
    ACCEPT = 0,
    TCP,
    UDP,
    Timer ,
    Event,
    File,
    None
}
// 所有检测的不同都有Watcher区分， 保证上层socket的代码都是公共代码
@trusted abstract class Watcher {
    this(WatcherType type_){
        _type = type_;
    }

    /// Whether the watcher is active.
    bool active(){
        return false;
    }

    abstract bool isError();

    abstract string erroString();

    final ushort flags(){return _flags;} 
    final @property type(){return _type;}

    void enableRead(){}
    void enableWrite(){}

    bool isEnableRead();
    bool isEnableWrite();

protected:
    //基于bit 区分标志
    // bit0: read, bit1: write,  bit8: TimerOnce, bit16:ET mode,
    ushort _flags;
private:
    WatcherType _type;
package (kiss):
    Watcher _priv;
    Watcher _next;
}


@trusted interface  ReadTransport {
    void onRead(Watcher watcher) nothrow;

    void onClose(Watcher watcher) nothrow;
}


//@Transport 

@trusted interface WriteTransport {
    void onWrite(Watcher watcher) nothrow;

    void onClose(Watcher watcher) nothrow;
}


@trusted interface Transport  : ReadTransport, WriteTransport {
}

// 实际处理
interface LoopBase {
    Watcher createWatcher(WatcherType type);

    void read(Watcher watcher,scope ReadCallBack read);

    bool write(Watcher watcher,in ubyte[] data, out size_t writed);

    // 关闭会自动unRegister的
    bool close(Watcher watcher);

    bool register(Watcher watcher);

    bool unRegister(Watcher watcher);

    // while(true)
    void join(scope void delegate()nothrow weak); 

    void stop();
}

