module kiss.aio.AsyncTcpClient;

import kiss.aio.AsyncTcpBase;
import kiss.time.timer;

import std.string;
import std.socket;
import std.experimental.logger;
import kiss.event.Poll;
import kiss.event.Event;
import std.conv;

class AsyncTcpClient:AsyncTcpBase
{

	//public function below

	this(Poll poll , int reconnecttime = 5 * 1000, int client_keepalivetime = 60 * 1000)
	{
		super(poll);
		_reconnecttime = reconnecttime;
		_client_keepalivetime = client_keepalivetime;
	}

	bool open(string host , ushort port)
	{
		string strPort = to!string(port);
		AddressInfo[] arr = getAddressInfo(host , strPort , AddressInfoFlags.CANONNAME);
		if(arr.length == 0)
		{
			log(LogLevel.error , host ~ ":" ~ strPort);
			return false;
		}
		
		_host = host;
		_port = port;
		_socket = new Socket(arr[0].family , arr[0].type , arr[0].protocol);
		_socket.blocking(false);
		_socket.connect(arr[0].address);
		
		poll.addEvent(this , _socket.handle , _curEventType = IOEventType.IO_EVENT_WRITE);
		_status = Connect_Status.CLIENT_CONNECTING;
		return true;
	}


	//protected function below

	override protected bool onEstablished()
	{
		log(LogLevel.info , "client onOpen");
		_client_keepalive = poll.addTimer(this , 60 * 1000 , WheelType.WHEEL_PERIODIC);
		return poll.modEvent(this ,_socket.handle , _curEventType =  IOEventType.IO_EVENT_READ);
	}

	override protected bool onTimer(TimerFd fd , ulong ticks) {

		if(fd == _reconnect)
		{
			log(LogLevel.warning , "timer to reconnecting ");
			open(_host , _port); 
			return true;
		}
		else if(fd == _client_keepalive)
		{

			return true;
		}
		return super.onTimer(fd,ticks);
	}


	override protected bool onWrite()
	{
		if(_status == Connect_Status.CLIENT_CONNECTING)
		{
			log(LogLevel.info , "client connected");
			_status = Connect_Status.CLIENT_CONNECTED;
			return super.open();
		}

		return super.onWrite();
	}

	override protected bool onClose()
	{
		_status = Connect_Status.CLIENT_UNCONNECTED;
		super.onClose();
		if(_reconnect !is null)
			poll.delTimer(_reconnect);
		_reconnect = poll.addTimer(this , 5 * 1000 , WheelType.WHEEL_ONESHOT);

		if(_client_keepalive !is null)
		{	
			poll.delTimer(_client_keepalive);
			_client_keepalive = null;
		}

		return false;
	}


	//private member's below

	enum Connect_Status
	{
		CLIENT_UNCONNECTED = 0,
		CLIENT_CONNECTING,
		CLIENT_CONNECTED,
	}

	protected Connect_Status _status = Connect_Status.CLIENT_UNCONNECTED;
	protected TimerFd		 _reconnect;
	protected TimerFd		 _client_keepalive;
	protected int			 _reconnecttime;
	protected int 			 _client_keepalivetime;
	protected string		 _host;
	protected ushort		 _port;
}

