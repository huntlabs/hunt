/*
 * KISS - A refined core library for dlang
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module kiss.aio.AsynchronousChannelBase;

import kiss.aio.AsynchronousChannelThreadGroup;
import kiss.aio.AsynchronousChannelSelector;
import kiss.aio.AsynchronousSocketChannel;
import kiss.aio.AsynchronousSelectionKey;
import kiss.aio.ByteBuffer;
import kiss.aio.CompletionHandle;
import kiss.aio.Event;

import core.stdc.errno;

import std.socket;
import std.stdio;
import std.experimental.logger;

class AsynchronousChannelBase
{
	public
	{
		this(AsynchronousChannelThreadGroup group, AsynchronousChannelSelector sel)
		{
			_selector = sel;
			_group = group;
		}

		void setOpen(bool b)
		{
			_isOpen = b;
		}
		
		bool isOpen()
		{
			return _isOpen;
		}
		
		socket_t getFd()
		{
			return _socket.handle;
		}

		void close()
		{
			_isReadyClose = true;
		}

		AsynchronousChannelThreadGroup getGroup()
		{
			return _group;
		}

		void read(ByteBuffer buffer, ReadCompletionHandle handle, void* attachment)
		{
			register(AIOEventType.OP_READED,  cast(void*)handle, attachment, buffer) ;
		}

		void write(ByteBuffer buffer, WriteCompletionHandle handle, void* attachment)
		{
			register(AIOEventType.OP_WRITEED,  cast(void*)handle, attachment, buffer) ;
		}

		Socket socket()
		{
			return _socket;
		}

		void setSocket(Socket socket)
		{
			_socket = socket;
			_socket.blocking(false);
		}

		abstract int validOps();

		int intrestOps()
		{
			return _intrestOps;
		}

		bool onClose()
		{
			_selector._epoll.delEvent(_key , _socket.handle , AIOEventType.OP_NONE);
			_socket.close();

			return true;
		}

		bool isReadyClose()
		{
			return _isReadyClose;
		}
	}

	protected void register(int ops, void* handle, void* attchment, ByteBuffer obj = null)
    {
        if (!checkVailid(ops))
		{
            return ;
		}

        bool isNew = false;

        if (_intrestOps == -1 && _key is null)
        {
            _key = new AsynchronousSelectionKey();
            _key.selector(_selector);
            _key.channel(this);
            isNew = true;
        }
		
        _key.handle(handle);
        _key.interestOps(ops, isNew);
        _key.handleAttachment(attchment);
        _key.attachment(obj);
        _intrestOps = ops;
    }

	private bool checkVailid(int ops)
    {
        if (!isOpen())
        {
            log(LogLevel.info , "Channel was closed!!!");
            return false;
        }
		
        if ((ops & ~validOps()) != 0)
        {
            log(LogLevel.info , "Channel unsupport ops!!!",ops);
            return false;
        }
		
        return true;
    }

	protected
	{
		AsynchronousSelectionKey _key; 
		AsynchronousChannelSelector _selector;
		ByteBuffer _attachment;
		void* _handle;
		void* _handleAttachment;
		Socket _socket;
	}

	private
	{
		AsynchronousChannelThreadGroup _group;
		bool _isOpen = false;
		bool _isReadyClose = false;
		int _intrestOps = -1;
	}
}
