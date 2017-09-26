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
			register(AIOEventType.OP_READED,  cast(void*)handle,  attachment, buffer);
		}

		void write(string buffer, WriteCompletionHandle handle, void* attachment) {
			ByteBuffer b = ByteBuffer.allocate(cast(int)(buffer.length + 1));
			b.put(cast(byte[])buffer);
			write(b, handle, attachment);
		}

		void write(ByteBuffer buffer, WriteCompletionHandle handle, void* attachment)
		{	
			synchronized (this) {
				if (_writeBufferQueue.empty()) {
					long len = socket().send(buffer.getCurBuffer());
					if (buffer.getCurBuffer().length == len){							
						handle.onWriteCompleted(attachment, cast(size_t)(len), buffer);
						buffer.destroy();
						return;
					}
					else {
						if (errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) {
							close();
							return;
						}
						if (len > 0)
							buffer.offsetLimit(len);
					}
				}
				AsynchronousSelectionKey key = new AsynchronousSelectionKey();
				key.handle = cast(void*)handle;
				key.attchment = attachment;
				key.obj = buffer;
				WriteBufferData data = new WriteBufferData();
				data.key = key;
				_writeBufferQueue.enQueue(data);
			}
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

		void onReady() {
			_selector.addEvent(this,  cast(int)(_socket.handle),  EventType.READ | EventType.WRITE | EventType.ETMODE);
			_intrestOps |= AIOEventType.OP_WRITEED | AIOEventType.OP_READED;
		}

		override bool onWrite() {
			if (isConnected())
			{
				_intrestOps = _intrestOps & ~AIOEventType.OP_CONNECTED;
				if (errno == EBADF) {
					(cast(ConnectCompletionHandle)(_connectKey.handle)).onConnectFailed(_connectKey.attchment);
					onClose();
					_connectKey = AsynchronousSelectionKey.init;
				}
				else {
					(cast(ConnectCompletionHandle)(_connectKey.handle)).onConnectCompleted(_connectKey.attchment);
					_intrestOps |= AIOEventType.OP_WRITEED | AIOEventType.OP_READED;
				}
				return true;
			}
			else if (isWriteed()) 
			{   
				synchronized (this) {
					while(!_writeBufferQueue.empty()) {
						WriteBufferData data =  _writeBufferQueue.front();
						ByteBuffer b = data.key.obj;
						long len = socket().send(b.getCurBuffer());

						if (b.getCurBuffer().length == 0){
							_writeBufferQueue.deQueue();								
							(cast(WriteCompletionHandle)(data.key.handle)).onWriteCompleted(data.key.attchment, cast(size_t)(b.getPosition()), b);
							b.destroy();
							continue;
						}
						if (len > 0) {
							if (b.offsetLimit(len)) {
								_writeBufferQueue.deQueue();					
								(cast(WriteCompletionHandle)(data.key.handle)).onWriteCompleted(data.key.attchment, cast(size_t)(b.getPosition()), b);
								b.destroy();
							}
							continue;
						}
						else {
							if (errno == EAGAIN || errno == EWOULDBLOCK)
								return true;
							else if (errno == EINTR)
								continue;
						}
						log("write error ", errno);
						return false;
					}
				}
			}
			return true;
		}

		override bool onRead() {
			
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
					client.onReady();
					(cast(AcceptCompletionHandle)(_acceptKey.handle)).onAcceptCompleted(_acceptKey.attchment, client);
				}
				return true;
			}
			else if (isReaded()) 
			{
				long len;
				while(isOpen()) {
					len = _socket.receive(_readKey.obj.getLeftBuffer());
					if (len > 0) {
						_readKey.obj.offsetPos(len);
						(cast(ReadCompletionHandle)(_readKey.handle)).onReadCompleted(_readKey.attchment, cast(size_t)(_readKey.obj.getPosition()), _readKey.obj);
						_readKey.obj.clear();
						continue;
					}
					else if(len < 0) {
						if (errno == EAGAIN || errno == EWOULDBLOCK) {
							return true;
						} else if (errno == EINTR) {
							log("Interrupted system call the socket ");
							continue;
						}
						log("read failed !", errno);
						(cast(ReadCompletionHandle)(_readKey.handle)).onReadFailed(_readKey.attchment);
						return false;
					}
					(cast(ReadCompletionHandle)(_readKey.handle)).onReadFailed(_readKey.attchment);
					return false;
				}
				return true;
			}
			return true;
		}

		

		override bool onClose()
		{
			_selector.delEvent(this , cast(int)(_socket.handle), EventType.NONE);
			_socket.close();
			_intrestOps = 0;
			_connectKey = null;
			setOpen(false);
			synchronized (this)
			{
				while (!_writeBufferQueue.empty())
				{
					WriteBufferData data = _writeBufferQueue.deQueue();
					(cast(WriteCompletionHandle)(data.key.handle)).onWriteFailed(data.key.attchment);
					data.key.obj.destroy();
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

	private bool createOrUpdateKey(ref AsynchronousSelectionKey key,  void* handle, void* attachment, ByteBuffer obj) {
		bool isNew = false;
		if (key is AsynchronousSelectionKey.init) {
			key = new AsynchronousSelectionKey();
			isNew = true;
		} 
		key.handle = handle;
		key.attchment = attachment;
		key.obj = obj;
		return isNew;
	}

	protected void register(int ops, void* handle, void* attachment, ByteBuffer obj = null)
    {
		if (!checkVailid(ops))
		{
            return ;
		}
		if (ops & AIOEventType.OP_ACCEPTED) {
			if (createOrUpdateKey( _acceptKey, handle, attachment, obj))
				_selector.addEvent(this,  cast(int)(_socket.handle),  EventType.READ | EventType.WRITE | EventType.ETMODE);
			
		}
		else if (ops & AIOEventType.OP_CONNECTED) {
			if (createOrUpdateKey( _connectKey, handle, attachment, obj))
				_selector.addEvent(this,  cast(int)(_socket.handle),  EventType.READ | EventType.WRITE | EventType.ETMODE);
		}
		else if (ops & AIOEventType.OP_READED) {
			createOrUpdateKey(_readKey, handle, attachment, obj);
		}
		_intrestOps |= ops;
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
