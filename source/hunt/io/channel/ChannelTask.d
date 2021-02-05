module hunt.io.channel.ChannelTask;

import hunt.event.selector.Selector;
import hunt.Functions;
import hunt.io.BufferUtils;
import hunt.io.ByteBuffer;
import hunt.io.channel.AbstractSocketChannel;
import hunt.io.channel.Common;
import hunt.io.IoError;
// import hunt.io.SimpleQueue;
import hunt.logging.ConsoleLogger;
import hunt.system.Error;
import hunt.util.queue;
import hunt.util.worker;


import std.format;
import std.socket;

import core.atomic;

/**
 * 
 */
class ChannelTask : Task {
    DataReceivedHandler dataReceivedHandler;
    private shared bool _isFinishing = false;
    private Queue!(ByteBuffer) _buffers;

    this() {
        _buffers = new SimpleQueue!(ByteBuffer);
    }

    void put(ByteBuffer buffer) {
        _buffers.push(buffer);
    }

    bool isFinishing () {
        return _isFinishing;
    }

    override protected void doExecute() {

        ByteBuffer buffer;
        DataHandleStatus handleStatus = DataHandleStatus.Pending;

        do {
            buffer = _buffers.pop();
            if(buffer is null) {
                version(HUNT_IO_DEBUG) {
                    warning("A null buffer poped");
                }
                break;
            }

            version(HUNT_IO_DEBUG) {
                tracef("buffer: %s", buffer.toString());
            }

            handleStatus = dataReceivedHandler(buffer);

            version(HUNT_IO_DEBUG) {
                tracef("Handle status: %s, buffer: %s", handleStatus, buffer.toString());
            }
            
            _isFinishing = isTerminated();
            if(!_isFinishing) {
                _isFinishing = handleStatus == DataHandleStatus.Done && !buffer.hasRemaining() && _buffers.isEmpty();
            }

            if(_isFinishing) {
                version(HUNT_DEBUG) {
                    if(buffer.hasRemaining() || !_buffers.isEmpty()) {
                        warningf("The buffered data lost");
                    }
                }
                break;
            }
        } while(true);
    }
}

