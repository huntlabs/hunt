/*
 * Kiss - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module kiss.util.functional;

public import std.functional;
public import std.traits;
import std.typecons;
import std.typetuple;

pragma(inline) auto bind(T, Args...)(T fun, Args args) if (isCallable!(T))
{
    alias FUNTYPE = Parameters!(fun);
    static if (is(Args == void))
    {
        static if (isDelegate!T)
            return fun;
        else
            return toDelegate(fun);
    }
    else static if (FUNTYPE.length > args.length)
    {
        alias DTYPE = FUNTYPE[args.length .. $];
        return delegate(DTYPE ars) {
            TypeTuple!(FUNTYPE) value;
            value[0 .. args.length] = args[];
            value[args.length .. $] = ars[];
            return fun(value);
        };
    }
    else
    {
        return delegate() { return fun(args); };
    }
}

unittest
{

    import std.stdio;
    import core.thread;

    class AA
    {
        void show(int i)
        {
            writeln("i = ", i); // the value is not(0,1,2,3), it all is 2.
        }

        void show(int i, int b)
        {
            b += i * 10;
            writeln("b = ", b); // the value is not(0,1,2,3), it all is 2.
        }

        void aa()
        {
            writeln("aaaaaaaa ");
        }

        void dshow(int i, string str, double t)
        {
            writeln("i = ", i, "   str = ", str, "   t = ", t);
        }
    }

    void listRun(int i)
    {
        writeln("i = ", i);
    }

    void listRun2(int i, int b)
    {
        writeln("i = ", i, "  b = ", b);
    }

    void list()
    {
        writeln("bbbbbbbbbbbb");
    }

    void dooo(Thread[] t1, Thread[] t2, AA a)
    {
        foreach (i; 0 .. 4)
        {
            auto th = new Thread(bind!(void delegate(int, int))(&a.show, i, i));
            t1[i] = th;
            auto th2 = new Thread(bind(&listRun, (i + 10)));
            t2[i] = th2;
        }
    }

    //  void main()
    {
        auto tdel = bind(&listRun);
        tdel(9);
        bind(&listRun2, 4)(5);
        bind(&listRun2, 40, 50)();

        AA a = new AA();
        bind(&a.dshow, 5, "hahah")(20.05);

        Thread[4] _thread;
        Thread[4] _thread2;
        // AA a = new AA();

        dooo(_thread, _thread2, a);

        foreach (i; 0 .. 4)
        {
            _thread[i].start();
        }

        foreach (i; 0 .. 4)
        {
            _thread2[i].start();
        }

    }
}
