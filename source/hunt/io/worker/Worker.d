module hunt.io.worker.Worker;

import hunt.io.ByteBuffer;
import core.thread;
import core.sync.condition;
import core.sync.mutex;
import std.container : DList;
import hunt.io.channel;

class Task(T) {
  this (T obj , ByteBuffer buffer)
  {
    this.channel = obj;
    this.buffer = buffer;
  }
  T channel;
  ByteBuffer buffer;
}


class Worker(T) {

	this()
  {
    _isExit = false;
    _mutex = new Mutex();
    _condition = new Condition(_mutex);
    _isExit = false;
    _thread = new Thread(() {
      doThreadProc();
    });
  }

  void doThreadProc()
  {
      do
      {
        Task!T task = null;
        {
          _condition.mutex().lock();
          if (_queue.empty())
          {
            _condition.wait();
          }else
          {
            task = _queue.front();
            _queue.removeFront();
          }
          _condition.mutex().unlock();
        }

        if (_isExit)
        {
          break;
        }
        if (task !is null && !((cast(AbstractChannel)(task.channel)).isClosed()))
        {
          auto handle  = task.channel.getDataReceivedHandler();
          if (handle !is null)
          {
            handle(task.buffer);
          }
        }
      } while (!_isExit);
  }

  void run()
  {
    _thread.start();
  }

  void put(Task!T task)
  {
    if(task !is null)
    {
      _condition.mutex().lock();
      _queue.insertBack(task);
      _condition.notify();
      _condition.mutex().unlock();
    }
  }

  private {
    bool                _isExit;
    Condition           _condition;
    Mutex               _mutex;
    Thread              _thread;
    DList!(Task!T)      _queue;
  }

}

