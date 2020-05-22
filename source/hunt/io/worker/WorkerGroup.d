module hunt.io.worker.WorkerGroup;

import std.stdio;
import std.container : DList;
import core.thread;
import core.sync.condition;
import core.sync.mutex;
import std.process;
import hunt.io.channel;
import hunt.io.BufferUtils;
import hunt.io.ByteBuffer;
import hunt.io.worker.Worker;


class WorkerGroup(T) {

	this(size_t threadSize = 1) {
    _mutex = new Mutex();
    _condition = new Condition(_mutex);
    _isExit = false;
    _threadSize = threadSize;

    _thread = new Thread(() {
      doThreadProc();
    });

    for(int i = 0 ; i < _threadSize ; ++i)
    {
        auto worker = new Worker!T();
       _workers[i] = worker;
    }
	}


  private
  {
    bool                _isExit;
    Condition           _condition;
    Mutex               _mutex;
    DList!(Task!T)      _queue;
    size_t              _threadSize;
    Thread              _thread;
    Worker!T[size_t]    _workers;
  }


  void put(T obj , ByteBuffer buffer)
  {
    if(obj !is null && buffer !is null)
    {
      auto task = new Task!T(obj, buffer);
      _condition.mutex().lock();
      _queue.insertBack(task);
      _condition.notify();
      _condition.mutex().unlock();
    }
  }

  void dispatch(Task!T task)
  {
      if (task !is null)
      {
        _workers[task.channel.handle % _threadSize].put(task);
      }
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

          dispatch(task);

      } while (!_isExit);

	    return ;
  }

  void stop()
  {
      _isExit = true;
  }

  void run()
  {
      foreach(worker ; _workers.byValue)
      {
            worker.run();
      }
      _thread.start();
  }
}

