module hunt.io.IoError;

enum ErrorKind
{
    NOTFOUND,           //An entity was not found, often a file.
    PERMISSIONENIED,    //The operation lacked the necessary privileges to complete.
    CONNECTIONEFUSED,   //The connection was refused by the remote server.
    CONNECTIONEESET,    //The connection was reset by the remote server.
    CONNECTIONABORTED,  //The connection was aborted (terminated) by the remote server.
    NOTCONNECTED,       //The network operation failed because it was not connected yet.
    ADDRINUSE,          //A socket address could not be bound because the address is already in use elsewhere.
    ADDRNOTAVAILABLE,   //A nonexistent interface was requested or the requested address was not local.
    BROKENPIPE,         //The operation failed because a pipe was closed.
    ALREADYEXISTS,      //An entity already exists, often a file.
    WOULDBLOCK,         //The operation needs to block to complete, but the blocking operation was requested to not occur.
    INVALIDINPUT,       //A parameter was incorrect.
    INVALIDDATA,        //Data not valid for the operation were encountered.
    TIMEDOUT,           //The I/O operation's timeout expired, causing it to be canceled.
    WRITEZERO,          //An error returned when an operation could not be completed because a call to write returned Ok(0).
    INTERRUPTED,        //This operation was interrupted.
    OTHER,              //Any I/O error not part of this list.
    UNEXPECTEDEOF       //An error returned when an operation could not be completed because an "end of file" was reached prematurely.
}

class IoError
{
    private
    {
        ErrorKind _errorCode;
        string    _errorMsg;
    }

    public ErrorKind errorCode()
    {
        return _errorCode;
    }

    public string errorMsg()
    {
        return  _errorMsg;
    }

    this(ErrorKind code , string msg)
    {
        this._errorCode = code;
        this._errorMsg = msg;
    }
}
