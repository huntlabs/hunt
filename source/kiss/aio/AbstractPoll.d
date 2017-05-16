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

 class AbstractPoll {
    abstract int poll(int milltimeout);
    abstract void wakeUp();
    abstract bool addEvent(Event event , int fd ,  int type);
	abstract bool delEvent(Event event , int fd , int type);
	abstract bool modEvent(Event event , int fd , int type);
 }
 
    
     