module kiss.array;

import core.stdc.string : memcpy;
/**
 * 移除数组中元素，并且数组下标前移。
 * return： 移除的个数
 * 注： 对数组的长度不做处理
*/
size_t arrayRemove(E)(ref E[] ary, auto ref E e) {
    E tv = E.init;
    size_t rm = 0;
    size_t site = 0;
    for (size_t j = site; j < ary.length; ++j) {
        if (ary[j] != e) {
            if(site != j) 
                memcpy(&ary[site], &ary[j], E.sizeof);
            site++;
        } else {
            doInitVaule(ary[j]);
            rm++;
        }
    }
    if(rm > 0) {
        auto size = ary.length - rm;
        auto rmed = ary[size .. $];
        ary = ary[0..size];
        fillWithMemcpy(rmed, tv);
    }
    return rm;
}

E[] removeSite(E)(ref E[] _array,size_t site) 
    in {
        assert(site < _array.length);
    } body{
        const size_t len = ary.length - 1;
        doInitVaule(_array[site]);
        for (size_t i = site; i < len; ++i) {
            memcpy(&(_array[i]), &(_array[i + 1]), T.sizeof);
        }
        E v = E.init;
        memcpy(&(_array[len]), &v, T.sizeof);
        _array = _array[0..len];
        return _array;
    }

void doInitVaule(E)(ref E v){
    static if(is(E == struct) && hasElaborateDestructor!E) {
        destroy(v);
    }
    memcpy(&v,&tv,E.sizeof);
}

//from std.experimental.allocator.package;
void fillWithMemcpy(T)(void[] array, auto ref T filler) nothrow
{
    import core.stdc.string : memcpy;
    import std.algorithm.comparison : min;
    if (!array.length) return;
    memcpy(array.ptr, &filler, T.sizeof);
    // Fill the array from the initialized portion of itself exponentially.
    for (size_t offset = T.sizeof; offset < array.length; )
    {
        size_t extent = min(offset, array.length - offset);
        memcpy(array.ptr + offset, array.ptr, extent);
        offset += extent;
    }
}

unittest {
    import std.stdio;

    int[] a = [0, 0, 0, 4, 5, 4, 0, 8, 0, 2, 0, 0, 0, 1, 2, 5, 8, 0];
    writeln("length a  = ", a.length, "   a is : ", a);
    int[] b = a.dup;
    auto rm = arrayRemove(b, 0);
    writeln("length b  = ", b.length, "   b is : ", b);
    assert(b == [4, 5, 4, 8, 2, 1, 2, 5, 8]);

    int[] c = a.dup;
    rm = arrayRemove(c, 8);
    writeln("length c  = ", c.length, "   c is : ", c);

    assert(c == [0, 0, 0, 4, 5, 4, 0, 0, 2, 0, 0, 0, 1, 2, 5, 0]);

    int[] d = a.dup;
    rm = arrayRemove(d, 9);
    writeln("length d = ", d.length, "   d is : ", d);
    assert(d == a);
}
