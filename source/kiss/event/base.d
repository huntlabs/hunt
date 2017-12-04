module kiss.event.base;

import std.bitmanip;

alias ReadCallBack = void delegate(Object obj) nothrow;

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

enum WatchFlag : ushort
{
    None = 0,
    Read,
    Write,

    OneShot = 8,
    ETMode = 16
}

// 所有检测的不同都有Watcher区分， 保证上层socket的代码都是公共代码
@trusted abstract class Watcher {
    this(WatcherType type_){
        _type = type_;
        _flags = BitArray([false,false,false,false,
                            false,false,false,false,
                            false,false,false,false,
                            false,false,false,false]);
    }

    /// Whether the watcher is active.
    final bool active(){
        return (_inLoop !is null);
    }

    abstract bool isError();
    abstract string erroString();
    void onClose(){}
    void onRead(){}
    void onWrite(){}

    final bool flag(WatchFlag index){return _flags[index];} 
    final @property type(){return _type;}

    final void close(){
        if(_inLoop is null) return;
        _inLoop.close(this);
    }

protected:
    final void setFlag(WatchFlag index, bool enable){
        _flags[index] = enable;
    }
private:
    BitArray _flags;
    WatcherType _type;
    // 注册的eventLoop
    BaseLoop _inLoop;
private: // 设置一个双向链表，让GC能扫描，也让自己能处理。
    Watcher _priv;
    Watcher _next;

package (kiss.event): // 给 eventloop的，好操作一些信息，做处理。
    @property BaseLoop currtLoop(){return _inLoop;}
    @property void currtLoop(BaseLoop loop){_inLoop = loop;}

    void setNext(Watcher next){
        if(next is this) return;
        next._next = _next;
        next._priv = this;
        if (_next)
            _next._priv = next;
        this._next = next;
    } 

    void clear(){
        if(_priv)
            _priv._next = _next;
        if(_next)
            _next._priv = _priv;
        _next = null;
        _priv = null;
    }
}


@trusted interface  ReadTransport {

    void close();

    bool watched();

    bool watch();

    void onRead(Watcher watcher) nothrow;

    void onClose(Watcher watcher) nothrow;
}


//@Transport 

@trusted interface WriteTransport {
    bool watched();

    bool watch();
    
    void onWrite(Watcher watcher) nothrow;

    void onClose(Watcher watcher) nothrow;
}


@trusted interface Transport  : ReadTransport, WriteTransport {
}

// 实际处理
interface BaseLoop {
    Watcher createWatcher(WatcherType type);

    bool read(Watcher watcher,scope ReadCallBack read);

    bool write(Watcher watcher,in ubyte[] data, out size_t writed);

    // 关闭会自动unRegister的
    bool close(Watcher watcher);

    bool register(Watcher watcher);

    bool reRegister(Watcher watcher);

    bool unRegister(Watcher watcher);

    bool weakUp();

    // while(true)
    void join(scope void delegate()nothrow weak); 

    void stop();
}

