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

import kiss.aio.ByteBuffer;
import kiss.aio.CompletionHandle;
import kiss.aio.Event;
import kiss.aio.task;
import kiss.aio.WriteBufferData;
import kiss.util.Common;

import core.stdc.errno;

import std.socket;
import std.stdio;
import std.experimental.logger;
import core.sys.posix.sys.socket;









class AsynchronousChannelBase : Event
{
	public
	{
		this( AsynchronousChannelSelector sel)
		{
			_selector = sel;
			_writeBufferQueue = new WriteBufferDataQueue();


		}

		void setOpen(bool b) {
			_isOpen = b;
		}
		
		bool isOpen() {
			return _isOpen;
		}
		
		socket_t getFd() {
			return _socket.handle;
		}

		void close() {
			_isReadyClose = true;
		}

		

		void read(ByteBuffer buffer, ReadCompletionHandle handle, void* attachment) {
			register(AIOEventType.OP_READED,  cast(void*)handle, attachment, buffer);
		}

		void write(string buffer, WriteCompletionHandle handle, void* attachment) {
			ByteBuffer b = ByteBuffer.allocate(cast(int)(buffer.length + 1));
			b.put(cast(byte[])buffer);
			write(b, handle, attachment);
		}

		void write(ByteBuffer buffer, WriteCompletionHandle handle, void* attachment)
		{	
			synchronized (this) {
				bool isEmpty = _writeBufferQueue.empty();
				AsynchronousSelectionKey key = new AsynchronousSelectionKey();
				key.handle = cast(void*)handle;
				key.attchment = attachment;
				key.obj = buffer;
				WriteBufferData data = new WriteBufferData();
				data.key = key;
				_writeBufferQueue.enQueue(data);
				if (isEmpty) {
					register(cast(int)AIOEventType.OP_WRITEED, cast(void*)this, null, null);
				}
			}
		}
	

		public void unRegisterOp(AIOEventType ops)
		{
			int newOps = _intrestOps & ~ops;
			int newWriteAble = getReadWriteAble(newOps);

			_selector.modEvent(this,  cast(int)(_socket.handle),  newWriteAble, getReadWriteAble(_intrestOps));
		
			_intrestOps = newOps;	
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

		bool isAccepted() {
			return (_intrestOps & AIOEventType.OP_ACCEPTED) != 0;
		}

		bool isConnected() {
			return (_intrestOps & AIOEventType.OP_CONNECTED) != 0;
		}
		bool isReaded() {
			return (_intrestOps & AIOEventType.OP_READED) != 0;
		}

		bool isWriteed() {
			return (_intrestOps & AIOEventType.OP_WRITEED) != 0;
		}

		

		override bool onWrite() {
			// log("isWriteed",isWriteed());
			if (!isWriteed())
				log("_writeBufferQueue ",_writeBufferQueue._count);
			if (isConnected())
			{
				unRegisterOp(AIOEventType.OP_CONNECTED);
				if (errno == EBADF)
					(cast(ConnectCompletionHandle)(_connectKey.handle)).onConnectFailed(_connectKey.attchment);
				else 
					(cast(ConnectCompletionHandle)(_connectKey.handle)).onConnectCompleted(_connectKey.attchment);
				return true;
			}
			else if (isWriteed()) 
			{   
				synchronized (this) {
					while(!_writeBufferQueue.empty())
					{
						WriteBufferData data =  _writeBufferQueue.front();
						ByteBuffer b = data.key.obj;
						while(true) {
							long n = b.getCurBuffer().length;
							long len = socket().send(b.getCurBuffer());
							if (len == n) {
								b.offsetLimit(len);
								(cast(WriteCompletionHandle)(data.key.handle)).onWriteCompleted(data.key.attchment, cast(size_t)(b.getPosition()), b);
								_writeBufferQueue.deQueue();
								break;
							}
							else if (len < n) {
								if (len == -1 && errno != EAGAIN && errno != EWOULDBLOCK) {
									return false;
								}
								b.offsetLimit(len);
								return true;
							}
							else {
								b.offsetLimit(len);
							}
						}
					}
					unRegisterOp(AIOEventType.OP_WRITEED);
					return true;
				} 
			}
			return true;
		}

		override bool onRead() {
			//log("isReaded",isReaded());
			if (isAccepted())
			{   
				while(true) {
					socket_t fd = cast(socket_t)(.accept(_socket.handle, null, null));
					if (fd <= 0)
						break;
					Socket so = new Socket(fd, socket().addressFamily);
					AsynchronousSocketChannel client = AsynchronousSocketChannel.open(_selector);
					client.setOpen(true);
					client.setSocket(so);
					(cast(AcceptCompletionHandle)(_acceptKey.handle)).onAcceptCompleted(_acceptKey.attchment, client);
				}
				return true;
			}
			else if (isReaded()) 
			{
				long len;
				while((len = _socket.receive(_readKey.obj.getLeftBuffer())) > 0) {
					_readKey.obj.offsetPos(len);
				}
				if(len == -1 && errno != EAGAIN && errno != EWOULDBLOCK){
					(cast(ReadCompletionHandle)(_readKey.handle)).onReadFailed(_readKey.attchment);
					return false;
				}
				(cast(ReadCompletionHandle)(_readKey.handle)).onReadCompleted(_readKey.attchment, cast(size_t)(_readKey.obj.getPosition()), _readKey.obj);
				return true;
			}
			return true;
		}

		

		override bool onClose()
		{
			_selector.delEvent(this , cast(int)(_socket.handle), EventType.NONE);
			_socket.close();
			setOpen(false);
			synchronized (this)
			{
				while (!_writeBufferQueue.empty())
				{
					WriteBufferData data = _writeBufferQueue.deQueue();
					(cast(WriteCompletionHandle)(data.key.handle)).onWriteFailed(data.key.attchment);
				}
			}

			if (_onCloseHandle !is null) {
				_onCloseHandle();
			}

			return true;
		}

		override bool isReadyClose()
		{
			return _isReadyClose;
		}
	}

	public void setOnCloseHandle(OnCloseHandle handle) {
		_onCloseHandle = handle;
	}

	public void addTask(bool MustInQueue = true)(AbstractTask task)
	{
		_selector.addTask!(MustInQueue)(task);
	}

	private bool createOrUpdateKey(int ops, ref AsynchronousSelectionKey key,  void* handle, void* attchment, ByteBuffer obj) {
		if (key is AsynchronousSelectionKey.init) {
			key = new AsynchronousSelectionKey();
		} 
		bool isNew = true; 
		if (getReadWriteAble(ops) & getReadWriteAble(_intrestOps)) {
			isNew = false;
		}
		key.handle = handle;
		key.attchment = attchment;
		key.obj = obj;
		return isNew;
	}

	protected void register(int ops, void* handle, void* attchment, ByteBuffer obj = null)
    {
        if (!checkVailid(ops))
		{
            return ;
		}
		if (ops & AIOEventType.OP_ACCEPTED) {
			if (createOrUpdateKey(ops, _acceptKey, handle, attchment, obj))	{
				_selector.addEvent(this,  cast(int)(_socket.handle),  getReadWriteAble(ops));
			}
		}
		else if (ops & AIOEventType.OP_CONNECTED) {
			if (createOrUpdateKey(ops, _connectKey, handle, attchment, obj)) {
				_selector.addEvent(this,  cast(int)(_socket.handle),  getReadWriteAble(ops));
				_isClient = true;
			}
		}
		else if (ops & AIOEventType.OP_READED) {
			if (createOrUpdateKey(ops, _readKey, handle, attchment, obj)) {
				if (_isClient) 
					_selector.modEvent(this,  cast(int)(_socket.handle),  EventType.READ|EventType.ETMODE, getReadWriteAble(_intrestOps));
				else 
					_selector.addEvent(this,  cast(int)(_socket.handle),  getReadWriteAble(ops));
			}
		}
		else if (ops & AIOEventType.OP_WRITEED) { 
			_intrestOps |= ops;
			_selector.modEvent(this,  cast(int)(_socket.handle),  getReadWriteAble(_intrestOps | ops), getReadWriteAble(_intrestOps));
			
		}
		if (!(_intrestOps & ops)) {
			static if (IOMode != IO_MODE.epoll) {
				_selector.modEvent(this,  cast(int)(_socket.handle),  getReadWriteAble(ops), getReadWriteAble(_intrestOps));
			}
			_intrestOps |= ops;
		}

    }

	private int getReadWriteAble(int ops) {
		int ret = 0;
		if (ops & AIOEventType.OP_ACCEPTED || ops & AIOEventType.OP_READED) {
			ret |= EventType.READ;
			static if (IOMode == IO_MODE.epoll) {
				if (ops & AIOEventType.OP_READED) 
					ret |= EventType.ETMODE;
			}
		}
		if (ops & AIOEventType.OP_CONNECTED || ops & AIOEventType.OP_WRITEED) {
			ret |= EventType.WRITE;
			static if (IOMode == IO_MODE.epoll) {
				if (ops & AIOEventType.OP_WRITEED) 
					ret |= EventType.ETMODE;
			}
		}
		return ret;
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
		AsynchronousChannelSelector _selector;
		Socket _socket;
		bool _isClient = false;
	}

	private
	{

		AsynchronousSelectionKey _acceptKey;
		AsynchronousSelectionKey _connectKey;
		AsynchronousSelectionKey _readKey;


		OnCloseHandle _onCloseHandle = null;

		WriteBufferDataQueue _writeBufferQueue;
		bool _isOpen = false;
		bool _isReadyClose = false;
		int _intrestOps = 0;
	}

	
}
