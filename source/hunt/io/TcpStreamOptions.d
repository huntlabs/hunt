module hunt.io.TcpStreamOptions;

import core.time;

/**
 * 
 */
class TcpStreamOptions {
    
    // http://www.tldp.org/HOWTO/TCP-Keepalive-HOWTO/usingkeepalive.html
    /// the interval between the last data packet sent (simple ACKs are not considered data) and the first keepalive probe; 
    /// after the connection is marked to need keepalive, this counter is not used any further 
    int keepaliveTime = 7200; // in seconds

    /// the interval between subsequential keepalive probes, regardless of what the connection has exchanged in the meantime 
    int keepaliveInterval = 75; // in seconds

    /// the number of unacknowledged probes to send before considering the connection dead and notifying the application layer 
    int keepaliveProbes = 9; // times

    bool isKeepalive = false;

    size_t bufferSize = 1024 * 8;

    int retryTimes = 5;
    Duration retryInterval = 2.seconds;

    this() {

    }

    static TcpStreamOptions create() {
        TcpStreamOptions option = new TcpStreamOptions();
        option.isKeepalive = true;
        option.keepaliveTime = 15;
        option.keepaliveInterval = 3;
        option.keepaliveProbes = 5;
        option.bufferSize = 1024 * 8;
        return option;
    }
}