module kiss.event.impl.epoll;

import kiss.event.base;
import kiss.event.watcher;

class EpollTCPWatcher : TCPSocketWatcher
{}

class EpollTimerWatcher : TimerWatcher
{}

class EpollUDPWatcher : UDPSocketWatcher
{}

class EpollAcceptWatcher : AcceptorWatcher
{}

class EpollLoop : LoopBase
{}
