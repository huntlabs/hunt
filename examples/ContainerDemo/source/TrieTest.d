module TrieTest;


import hunt.container.ArrayTernaryTrie;
import hunt.container.ArrayTrie;
import hunt.container.ByteBuffer;
import hunt.container.Collection;
import hunt.container.TreeTrie;
import hunt.container.Trie;

import hunt.container.BufferUtils;

import hunt.util.UnitTest;
import hunt.util.Assert;
import hunt.util.string;

import kiss.logger;
import std.conv;

/**
https://www.programcreek.com/java-api-examples/index.php?source_dir=jetty.project-master/jetty-jaspi/src/test/java/org/eclipse/jetty/security/jaspi/JaspiTest.java#
*/
class TrieTest { 
    // static Object[][] data() 
    // { 
    //     Object[][] data = [ 
    //         [cast(Object)new ArrayTrie!int(128)], 
    //         [cast(Object)new TreeTrie!int()], 
    //         [cast(Object)new ArrayTernaryTrie!int(128)] 
    //     ]; 
    //     return data; 
    // } 
 
    Trie!int trie; 

    this() {
        trie= new ArrayTrie!int(128); 
        // trie= new TreeTrie!int(); 
        // trie= new ArrayTernaryTrie!int(128); 
        before();
    }
     
    // this(Trie!int t) 
    // { 
    //     trie=t; 
    // } 
     
    void before() 
    { 
        trie.put("hello",1); 
        trie.put("He",2); 
        trie.put("HELL",3); 
        trie.put("wibble",4); 
        trie.put("Wobble",5); 
        trie.put("foo-bar",6); 
        trie.put("foo+bar",7); 
        trie.put("HELL4",8); 
        trie.put("",9); 
    } 
 
    
    void testOverflow()
    { 
        int i=0; 
        while (true)  
        { 
            if (++i>10000) 
                break; // must not be fixed size 
            if (!trie.put("prefix" ~ i.to!string(), i)) 
            { 
                assert(trie.isFull()); 
                break; 
            } 
        } 
         
        assert(!trie.isFull() || !trie.put("overflow", 0)); 
    } 
    
    void testKeySet()
    { 
        // trace(trie.keySet().toString());

        assert(trie.keySet().contains("hello")); 
        assert(trie.keySet().contains("He")); 
        assert(trie.keySet().contains("HELL")); 
        assert(trie.keySet().contains("wibble")); 
        assert(trie.keySet().contains("Wobble")); 
        assert(trie.keySet().contains("foo-bar")); 
        assert(trie.keySet().contains("foo+bar")); 
        // assert(trie.keySet().contains("HELL4")); 
        
        // TODO: Tasks pending completion -@zxp at 8/25/2018, 9:23:50 PM
        // 
        // assert(trie.keySet().contains(""));         
    } 
     
    void testGetString()
    { 
        trace(trie.get("hello"));
        trace(trie.get("He"));
        trace(trie.get("HELL"));
        trace(trie.get("wibble"));
        Assert.assertEquals(1,trie.get("hello")); 
        Assert.assertEquals(2,trie.get("He")); 
        Assert.assertEquals(3,trie.get("HELL")); 
        Assert.assertEquals(4,trie.get("wibble")); 
        Assert.assertEquals(5,trie.get("Wobble")); 
        Assert.assertEquals(6,trie.get("foo-bar")); 
        Assert.assertEquals(7,trie.get("foo+bar")); 
         
        Assert.assertEquals(1,trie.get("Hello")); 
        Assert.assertEquals(2,trie.get("HE")); 
        Assert.assertEquals(3,trie.get("heLL")); 
        Assert.assertEquals(4,trie.get("Wibble")); 
        Assert.assertEquals(5,trie.get("wobble")); 
        Assert.assertEquals(6,trie.get("Foo-bar")); 
        Assert.assertEquals(7,trie.get("FOO+bar")); 
        Assert.assertEquals(8,trie.get("HELL4")); 
        Assert.assertEquals(9,trie.get("")); 
         
        Assert.assertEquals(int.init,trie.get("helloworld")); 
        Assert.assertEquals(int.init,trie.get("Help")); 
        Assert.assertEquals(int.init,trie.get("Blah")); 
    } 
 
    void testGetBuffer()
    { 
        Assert.assertEquals(1,trie.get(BufferUtils.toBuffer("xhellox"),1,5)); 
        Assert.assertEquals(2,trie.get(BufferUtils.toBuffer("xhellox"),1,2)); 
        Assert.assertEquals(3,trie.get(BufferUtils.toBuffer("xhellox"),1,4)); 
        Assert.assertEquals(4,trie.get(BufferUtils.toBuffer("wibble"),0,6)); 
        Assert.assertEquals(5,trie.get(BufferUtils.toBuffer("xWobble"),1,6)); 
        Assert.assertEquals(6,trie.get(BufferUtils.toBuffer("xfoo-barx"),1,7)); 
        Assert.assertEquals(7,trie.get(BufferUtils.toBuffer("xfoo+barx"),1,7)); 
         
        Assert.assertEquals(1,trie.get(BufferUtils.toBuffer("xhellox"),1,5)); 
        Assert.assertEquals(2,trie.get(BufferUtils.toBuffer("xHELLox"),1,2)); 
        Assert.assertEquals(3,trie.get(BufferUtils.toBuffer("xhellox"),1,4)); 
        Assert.assertEquals(4,trie.get(BufferUtils.toBuffer("Wibble"),0,6)); 
        Assert.assertEquals(5,trie.get(BufferUtils.toBuffer("xwobble"),1,6)); 
        Assert.assertEquals(6,trie.get(BufferUtils.toBuffer("xFOO-barx"),1,7)); 
        Assert.assertEquals(7,trie.get(BufferUtils.toBuffer("xFOO+barx"),1,7)); 
 
        Assert.assertEquals(int.init,trie.get(BufferUtils.toBuffer("xHelloworldx"),1,10)); 
        Assert.assertEquals(int.init,trie.get(BufferUtils.toBuffer("xHelpx"),1,4)); 
        Assert.assertEquals(int.init,trie.get(BufferUtils.toBuffer("xBlahx"),1,4)); 
    } 
     
    void testGetDirectBuffer()
    { 
        Assert.assertEquals(1,trie.get(BufferUtils.toDirectBuffer("xhellox"),1,5)); 
        Assert.assertEquals(2,trie.get(BufferUtils.toDirectBuffer("xhellox"),1,2)); 
        Assert.assertEquals(3,trie.get(BufferUtils.toDirectBuffer("xhellox"),1,4)); 
        Assert.assertEquals(4,trie.get(BufferUtils.toDirectBuffer("wibble"),0,6)); 
        Assert.assertEquals(5,trie.get(BufferUtils.toDirectBuffer("xWobble"),1,6)); 
        Assert.assertEquals(6,trie.get(BufferUtils.toDirectBuffer("xfoo-barx"),1,7)); 
        Assert.assertEquals(7,trie.get(BufferUtils.toDirectBuffer("xfoo+barx"),1,7)); 
         
        Assert.assertEquals(1,trie.get(BufferUtils.toDirectBuffer("xhellox"),1,5)); 
        Assert.assertEquals(2,trie.get(BufferUtils.toDirectBuffer("xHELLox"),1,2)); 
        Assert.assertEquals(3,trie.get(BufferUtils.toDirectBuffer("xhellox"),1,4)); 
        Assert.assertEquals(4,trie.get(BufferUtils.toDirectBuffer("Wibble"),0,6)); 
        Assert.assertEquals(5,trie.get(BufferUtils.toDirectBuffer("xwobble"),1,6)); 
        Assert.assertEquals(6,trie.get(BufferUtils.toDirectBuffer("xFOO-barx"),1,7)); 
        Assert.assertEquals(7,trie.get(BufferUtils.toDirectBuffer("xFOO+barx"),1,7)); 
 
        Assert.assertEquals(int.init,trie.get(BufferUtils.toDirectBuffer("xHelloworldx"),1,10)); 
        Assert.assertEquals(int.init,trie.get(BufferUtils.toDirectBuffer("xHelpx"),1,4)); 
        Assert.assertEquals(int.init,trie.get(BufferUtils.toDirectBuffer("xBlahx"),1,4)); 
    } 
    
    void testGetBestArray()
    { 
        Assert.assertEquals(1,trie.getBest(cast(byte[])("xhelloxxxx"),1,8)); 
        Assert.assertEquals(2,trie.getBest(cast(byte[])("xhelxoxxxx"),1,8)); 
        Assert.assertEquals(3,trie.getBest(cast(byte[])("xhellxxxxx"),1,8));  
        Assert.assertEquals(6,trie.getBest(cast(byte[])("xfoo-barxx"),1,8));  
        Assert.assertEquals(8,trie.getBest(cast(byte[])("xhell4xxxx"),1,8));  
         
        Assert.assertEquals(1,trie.getBest(cast(byte[])("xHELLOxxxx"),1,8)); 
        Assert.assertEquals(2,trie.getBest(cast(byte[])("xHELxoxxxx"),1,8)); 
        Assert.assertEquals(3,trie.getBest(cast(byte[])("xHELLxxxxx"),1,8));  
        Assert.assertEquals(6,trie.getBest(cast(byte[])("xfoo-BARxx"),1,8));  
        Assert.assertEquals(8,trie.getBest(cast(byte[])("xHELL4xxxx"),1,8));   
        Assert.assertEquals(9,trie.getBest(cast(byte[])("xZZZZZxxxx"),1,8));   
    } 
    
    void testGetBestBuffer()
    { 
        Assert.assertEquals(1,trie.getBest(BufferUtils.toBuffer("xhelloxxxx"),1,8)); 
        Assert.assertEquals(2,trie.getBest(BufferUtils.toBuffer("xhelxoxxxx"),1,8)); 
        Assert.assertEquals(3,trie.getBest(BufferUtils.toBuffer("xhellxxxxx"),1,8));  
        Assert.assertEquals(6,trie.getBest(BufferUtils.toBuffer("xfoo-barxx"),1,8));  
        Assert.assertEquals(8,trie.getBest(BufferUtils.toBuffer("xhell4xxxx"),1,8));  
         
        Assert.assertEquals(1,trie.getBest(BufferUtils.toBuffer("xHELLOxxxx"),1,8)); 
        Assert.assertEquals(2,trie.getBest(BufferUtils.toBuffer("xHELxoxxxx"),1,8)); 
        Assert.assertEquals(3,trie.getBest(BufferUtils.toBuffer("xHELLxxxxx"),1,8));  
        Assert.assertEquals(6,trie.getBest(BufferUtils.toBuffer("xfoo-BARxx"),1,8));  
        Assert.assertEquals(8,trie.getBest(BufferUtils.toBuffer("xHELL4xxxx"),1,8));   
        Assert.assertEquals(9,trie.getBest(BufferUtils.toBuffer("xZZZZZxxxx"),1,8));   
         
        ByteBuffer buffer = cast(ByteBuffer)BufferUtils.toBuffer("xhelloxxxxxxx").position(2); 
        Assert.assertEquals(1,trie.getBest(buffer,-1,10)); 
    } 
    
    void testGetBestDirectBuffer()
    { 
        Assert.assertEquals(1,trie.getBest(BufferUtils.toDirectBuffer("xhelloxxxx"),1,8)); 
        Assert.assertEquals(2,trie.getBest(BufferUtils.toDirectBuffer("xhelxoxxxx"),1,8)); 
        Assert.assertEquals(3,trie.getBest(BufferUtils.toDirectBuffer("xhellxxxxx"),1,8));  
        Assert.assertEquals(6,trie.getBest(BufferUtils.toDirectBuffer("xfoo-barxx"),1,8));  
        Assert.assertEquals(8,trie.getBest(BufferUtils.toDirectBuffer("xhell4xxxx"),1,8));  
         
        Assert.assertEquals(1,trie.getBest(BufferUtils.toDirectBuffer("xHELLOxxxx"),1,8)); 
        Assert.assertEquals(2,trie.getBest(BufferUtils.toDirectBuffer("xHELxoxxxx"),1,8)); 
        Assert.assertEquals(3,trie.getBest(BufferUtils.toDirectBuffer("xHELLxxxxx"),1,8));  
        Assert.assertEquals(6,trie.getBest(BufferUtils.toDirectBuffer("xfoo-BARxx"),1,8));  
        Assert.assertEquals(8,trie.getBest(BufferUtils.toDirectBuffer("xHELL4xxxx"),1,8));   
        Assert.assertEquals(9,trie.getBest(BufferUtils.toDirectBuffer("xZZZZZxxxx"),1,8));   
         
        ByteBuffer buffer = cast(ByteBuffer)BufferUtils.toDirectBuffer("xhelloxxxxxxx").position(2); 
        Assert.assertEquals(1,trie.getBest(buffer,-1,10)); 
    } 
     
    void testFull()
    { 
        ArrayTrie!int t1 = cast(ArrayTrie!int)trie;
        ArrayTernaryTrie!int t2 = cast(ArrayTernaryTrie!int)trie;
        if( t1 is null && t2 is null) return;
        
        Assert.assertFalse(trie.put("Large: This is a really large key and should blow the maximum size of the array trie as lots of nodes should already be used.",99)); 
        testGetString(); 
        testGetBestArray(); 
        testGetBestBuffer(); 
    } 
}