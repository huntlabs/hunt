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

module kiss.aio.Event;



enum AIOEventType
{
	OP_NONE = 0,
	OP_ACCEPTED = 1 << 0,
    OP_READED = 1 << 1,
    OP_WRITEED = 1 << 2,
    OP_CONNECTED = 1 << 3,
}


enum EventType {
    NONE = 0,
    READ = 1 << 0,
    WRITE = 1 << 1,
    TIMER = 1 << 2
}



interface Event
{
	bool onWrite();
    bool onRead();
    bool onClose();
	bool isReadyClose();
}
