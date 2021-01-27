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
    SimpleEventHandler finishedHandler;
    Queue!(ByteBuffer) buffers;

    this() {
        buffers = new SimpleQueue!(ByteBuffer);
    }

    override protected void doExecute() {

        scope(exit) {
            finish();
            version(HUNT_IO_DEBUG) {
                info("Task Done!");
            }

            if(finishedHandler !is null) {
                finishedHandler();
            }
        }

        ByteBuffer buffer;
        DataHandleStatus handleStatus = DataHandleStatus.Pending;

        do {
            buffer = buffers.pop();
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
            
            if(isTerminated() ||
                handleStatus == DataHandleStatus.Done && !buffer.hasRemaining()) {
                break;
            }
        } while(true);
    }
}

