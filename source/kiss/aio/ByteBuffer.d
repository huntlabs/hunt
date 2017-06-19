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

module kiss.aio.ByteBuffer;
import core.stdc.stdlib;
import core.stdc.string;
import std.algorithm;
import std.experimental.logger.core;
import std.stdio;
import core.memory;


class ByteBuffer {


public:
    static allocate(int Capacity) {
        return new ByteBuffer(Capacity);
    }
    this(int Capacity){
        _capacity = Capacity;
        _position = 0;
        _limit = 0;
        _buffer = new byte[_capacity];
    }
    ~this(){
        if (!(_buffer is null))
            GC.free(_buffer.ptr);
        _buffer = null;
    }

    void put(byte[] data)
    {
        if (_position == _capacity)
        {
            log(LogLevel.warning,"ByteBuffer cache full!!!");
            return;
        }
        size_t limit = data.length + _position;
        limit = min(limit, _capacity);
        _buffer[_position..limit] = data[0..limit];
		_position = limit;
    }

    byte[] getCurBuffer()
    {
        return _buffer[_limit.._position];
    }

    byte[] getExsitBuffer()
    {
        return _buffer[0.._position];
    }   

    void[] getLeftBuffer()
    {
        return _buffer[_position.._capacity];
    }


    
    void clear() {
        _position = 0;
        _limit = 0;
    }

    bool hasRemaining()
    {
        return _limit < _position;
    }

    void offsetPos(long add)
    {
        _position = _position + cast(size_t)add;
        _position = min(_position,_capacity);
        _position = max(_position,0);
    }

    size_t getPosition()
    {
        return _position;
    }

    void offsetLimit(long add)
    {
        _limit = _limit + cast(size_t)add;
        _limit = min(_limit,_position);
        _limit = max(_limit,0);
    }

    void flip()
    {
        log(LogLevel.warning , "ByteBuffer.flip do nothing!");
        return;
    }

    void release()
    {
        _position = 0;
        _limit = 0;
    }
    
    size_t _capacity;
    size_t _position;

private:
    byte[] _buffer;
    size_t _limit;


}