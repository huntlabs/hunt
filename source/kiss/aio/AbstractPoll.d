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

 module kiss.aio.AbstractPoll;

 import kiss.aio.Event;

 interface  AbstractPoll {
    int poll(int milltimeout);
    void wakeUp();
    bool addEvent(Event event , int fd ,  int type);
	bool delEvent(Event event , int fd , int type);
	bool modEvent(Event event , int fd , int type);
 }
 
    
     