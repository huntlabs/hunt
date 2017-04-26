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

enum IOEventType
{
	IO_EVENT_NONE = 0,
	IO_EVENT_READ = 1 << 0,
	IO_EVENT_WRITE = 1 << 1,
	IO_EVENT_ERROR = 1 << 2
}


enum AIOEventType
{
	OP_NONE = 0,
	OP_ACCEPTED = 1 << 1,
    OP_READED = 1 << 2,
    OP_WRITEED = 1 << 3,
    OP_CONNECTED = 1 << 4,
	OP_ERROR = 1 << 5
}



interface Event
{
	bool onWrite();
    bool onRead();
    bool onClose();

	bool isReadyClose();
}
