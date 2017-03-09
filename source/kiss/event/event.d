/*
 * 
 *
 * Copyright (C) 2017 Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the Apache-2.0 License.
 *
 */
module kiss.event.Event;

enum IOEventType
{
	IO_EVENT_NONE = 0,
	IO_EVENT_READ = 1 << 0,
	IO_EVENT_WRITE = 1 << 1,
	IO_EVENT_ERROR = 1 << 2
}


interface Event
{
	bool onWrite();
    bool onRead();
    bool onClose();

	bool isReadyClose();
}
