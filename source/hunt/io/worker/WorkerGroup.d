module hunt.io.worker.WorkerGroup;

import std.stdio;
import std.container : DList;
import core.thread;
import core.sync.condition;
import core.sync.mutex;
import std.process;
import hunt.io.channel;
import hunt.collection.BufferUtils;
import hunt.collection.ByteBuffer;


class WorkerGroup(T) {

	this(size_t threadSize = 1) {
    _mutex = new Mutex();
    _condition = new Condition(_mutex);
    _isExit = false;
    _threadSize = threadSize;
    _threadIndex = 0;
    for(int i = 0 ; i < _threadSize ; ++i)
    {
      Thread th = new Thread(() {
        try {
          doThreadProc();
        } catch (Throwable t) {
        }
      });
      _threadPool ~= th;
    }
	}

  class Task {
    this (T obj , ByteBuffer buffer)
    {
        this.channel = obj;
        this.buffer = buffer;
    }
    T channel;
    ByteBuffer buffer;
  }

  private
  {
    bool                _isExit;
    Condition           _condition;
    Mutex               _mutex;
    DList!Task          _queue;
    size_t              _threadSize;
    Thread[]            _threadPool;
    size_t[ulong]       _threadIdMap;
    size_t              _threadIndex;
  }


  void put(T obj , ByteBuffer buffer)
  {
    if(obj !is null && buffer !is null)
    {
      auto task = new Task(obj, buffer);
      _condition.mutex().lock();
      _queue.insertBack(task);
      _condition.notifyAll();
      _condition.mutex().unlock();
    }
  }

  void doThreadProc()
  {
      _threadIdMap[thisThreadID()] = _threadIndex;
      _threadIndex++;
    	do
      {
          Task task = null;
          {
            _condition.mutex().lock();
            if (_queue.empty())
            {
              _condition.wait();
            }else
            {
              task = _queue.front();
              auto channel = task.channel;
              if (channel !is null && (cast(size_t)channel.handle % _threadSize != _threadIdMap[thisThreadID()]))
              {
                task = null;
                _condition.wait();
              }else
              {
                _queue.removeFront();
              }
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
	    return ;
  }

  void stop()
  {
      _isExit = true;
  }

  void run()
  {
      foreach(i ; 0 .. _threadPool.length)
      {
        _threadPool[i].start();
      }
  }
}

