module BufferUtilsDemo;

import hunt.collection.ByteBuffer;
import hunt.collection.BufferUtils;
import hunt.logging;

import hunt.util.Assert;
import hunt.util.UnitTest;
import hunt.exception;

alias assertTrue = Assert.assertTrue;
alias assertFalse = Assert.assertFalse;
alias assertThat = Assert.assertThat;
alias assertEquals = Assert.assertEquals;
alias assertNotNull = Assert.assertNotNull;
alias assertNull = Assert.assertNull;

import std.conv;

class BufferUtilsDemo {

    @Test void testToInt() {
        ByteBuffer[] buf = [
            BufferUtils.toBuffer("0"), BufferUtils.toBuffer(" 42 "),
            BufferUtils.toBuffer("   43abc"), BufferUtils.toBuffer("-44"), BufferUtils.toBuffer(" - 45;"),
            BufferUtils.toBuffer("-2147483648"), BufferUtils.toBuffer("2147483647"),
        ];

        int[] val = [0, 42, 43, -44, -45, -2147483648, 2147483647];

        for (size_t i = 0; i < buf.length; i++)
            assertEquals("t" ~ i.to!string(), val[i], BufferUtils.toInt(buf[i]));
    }

    @Test void testPutInt() {
        int[] val = [0, 42, 43, -44, -45, int.min, int.max];

        string[] str = ["0", "42", "43", "-44", "-45", to!string(int.min), to!string(int.max)];

        ByteBuffer buffer = ByteBuffer.allocate(24);

        for (int i = 0; i < val.length; i++) {
            BufferUtils.clearToFill(buffer);
            BufferUtils.putDecInt(buffer, val[i]);
            BufferUtils.flipToFlush(buffer, 0);
            assertEquals("t" ~ i.to!string(), str[i], BufferUtils.toString(buffer));
        }
    }

    @Test void testPutLong() {
        long[] val = [0L, 42L, 43L, -44L, -45L, long.min, long.max];

        string[] str = ["0", "42", "43", "-44", "-45", to!string(long.min), to!string(long.max)];

        ByteBuffer buffer = ByteBuffer.allocate(50);

        for (int i = 0; i < val.length; i++) {
            BufferUtils.clearToFill(buffer);
            BufferUtils.putDecLong(buffer, val[i]);
            BufferUtils.flipToFlush(buffer, 0);
            assertEquals("t" ~ i.to!string(), str[i], BufferUtils.toString(buffer));
        }
    }

    @Test void testPutHexInt() {
        int[] val = [0, 42, 43, -44, -45, -2147483648, 2147483647];

        string[] str = ["0", "2A", "2B", "-2C", "-2D", "-80000000", "7FFFFFFF"];

        ByteBuffer buffer = ByteBuffer.allocate(50);

        for (int i = 0; i < val.length; i++) {
            BufferUtils.clearToFill(buffer);
            BufferUtils.putHexInt(buffer, val[i]);
            BufferUtils.flipToFlush(buffer, 0);
            assertEquals("t" ~ i.to!string, str[i], BufferUtils.toString(buffer));
        }
    }

    @Test void testPut() {
        ByteBuffer to = BufferUtils.allocate(10);
        ByteBuffer from = BufferUtils.toBuffer("12345");

        BufferUtils.clear(to);
        assertEquals(5, BufferUtils.append(to, from));
        assertTrue(BufferUtils.isEmpty(from));
        assertEquals("12345", BufferUtils.toString(to));

        from = BufferUtils.toBuffer("XX67890ZZ");
        from.position(2);

        assertEquals(5, BufferUtils.append(to, from));
        assertEquals(2, from.remaining());
        assertEquals("1234567890", BufferUtils.toString(to));
    }

    @Test void testAppend() {
        ByteBuffer to = BufferUtils.allocate(8);
        ByteBuffer from = BufferUtils.toBuffer("12345");

        BufferUtils.append(to, from.array(), 0, 3);
        assertEquals("123", BufferUtils.toString(to));
        BufferUtils.append(to, from.array(), 3, 2);
        assertEquals("12345", BufferUtils.toString(to));

        try {
            BufferUtils.append(to, from.array(), 0, 5);
            Assert.fail();
        } catch (BufferOverflowException e) {
        }
    }

    @Test void testPutDirect() {
        ByteBuffer to = BufferUtils.allocateDirect(10);
        ByteBuffer from = BufferUtils.toBuffer("12345");

        BufferUtils.clear(to);
        assertEquals(5, BufferUtils.append(to, from));
        assertTrue(BufferUtils.isEmpty(from));
        assertEquals("12345", BufferUtils.toString(to));

        from = BufferUtils.toBuffer("XX67890ZZ");
        from.position(2);

        assertEquals(5, BufferUtils.append(to, from));
        assertEquals(2, from.remaining());
        assertEquals("1234567890", BufferUtils.toString(to));
    }

        @Test
        void testToBuffer_Array() {
            byte[] arr = new byte[128];
            // Arrays.fill(arr, (byte) 0x44);
            arr[] = 0x44;
            ByteBuffer buf = BufferUtils.toBuffer(arr);

            int count = 0;
            while (buf.remaining() > 0) {
                byte b = buf.get();
                Assert.assertEquals(b, 0x44);
                count++;
            }

            Assert.assertEquals("Count of bytes", arr.length, count);
        }

        @Test
        void testToBuffer_ArrayOffsetLength() {
            byte[] arr = new byte[128];
            arr[] = cast(byte)0xFF; // fill whole thing with FF
            
            int offset = 10;
            int length = 100;
            arr[offset ..  offset + length] = 0x77;
            ByteBuffer buf = BufferUtils.toBuffer(arr, offset, length); // fill partial with 0x77

            int count = 0;
            while (buf.remaining() > 0) {
                byte b = buf.get();
                Assert.assertEquals(b, 0x77);
                count++;
            }

            Assert.assertEquals("Count of bytes", length, count);
        }

    //     @Test
    //     @Ignore("Very simple microbenchmark to compare different writeTo implementations. Only for development thus " ~
    //             "ignored.")
    //     void testWriteToMicrobenchmark() {
    //         int capacity = 1024 * 128;
    //         int iterations = 100;
    //         int testRuns = 10;
    //         byte[] bytes = new byte[capacity];
    //         ThreadLocalRandom.current().nextBytes(bytes);
    //         ByteBuffer buffer = BufferUtils.allocate(capacity);
    //         BufferUtils.append(buffer, bytes, 0, capacity);
    //         long startTest = System.nanoTime();
    //         for (int i = 0; i < testRuns; i++) {
    //             long start = System.nanoTime();
    //             for (int j = 0; j < iterations; j++) {
    //                 ByteArrayOutputStream out = new ByteArrayOutputStream();
    //                 long startRun = System.nanoTime();
    //                 BufferUtils.writeTo(buffer.asReadOnlyBuffer(), out);
    //                 long elapsedRun = System.nanoTime() - startRun;
    // //                LOG.warn("run elapsed={}ms", elapsedRun / 1000);
    //                 assertThat("Bytes in out equal bytes in buffer", Arrays.equals(bytes, out.toByteArray()), is(true));
    //             }
    //             long elapsed = System.nanoTime() - start;
    //             System.out.println(StringUtils.replace("elapsed={}ms average={}ms", elapsed / 1000, elapsed / iterations / 1000));
    //         }
    //         System.out.println(StringUtils.replace("overall average: {}ms", (System.nanoTime() - startTest) / testRuns / iterations / 1000));
    //     }

    //     @Test
    //     void testWriteToWithBufferThatDoesNotExposeArrayAndSmallContent() {
    //         int capacity = BufferUtils.TEMP_BUFFER_SIZE / 4;
    //         testWriteToWithBufferThatDoesNotExposeArray(capacity);
    //     }

    //     @Test
    //     void testWriteToWithBufferThatDoesNotExposeArrayAndContentLengthMatchingTempBufferSize() {
    //         int capacity = BufferUtils.TEMP_BUFFER_SIZE;
    //         testWriteToWithBufferThatDoesNotExposeArray(capacity);
    //     }

    //     @Test
    //     void testWriteToWithBufferThatDoesNotExposeArrayAndContentSlightlyBiggerThanTwoTimesTempBufferSize()
    //             throws
    //             IOException {
    //         int capacity = BufferUtils.TEMP_BUFFER_SIZE * 2 + 1024;
    //         testWriteToWithBufferThatDoesNotExposeArray(capacity);
    //     }

    @Test void testEnsureCapacity() {
        ByteBuffer b = BufferUtils.toBuffer("Goodbye Cruel World");
        assertTrue(b == BufferUtils.ensureCapacity(b, 0));
        assertTrue(b == BufferUtils.ensureCapacity(b, 10));
        assertTrue(b == BufferUtils.ensureCapacity(b, b.capacity()));

        ByteBuffer b1 = BufferUtils.ensureCapacity(b, 64);
        assertTrue(b != b1);
        assertEquals(64, b1.capacity());
        assertEquals("Goodbye Cruel World", BufferUtils.toString(b1));

        b1.position(8);
        b1.limit(13);
        assertEquals("Cruel", BufferUtils.toString(b1));
        ByteBuffer b2 = b1.slice();
        assertEquals("Cruel", BufferUtils.toString(b2));
        trace(BufferUtils.toDetailString(b2));
        assertEquals(8, b2.arrayOffset());
        assertEquals(5, b2.capacity());

        assertTrue(b2 == BufferUtils.ensureCapacity(b2, 5));

        ByteBuffer b3 = BufferUtils.ensureCapacity(b2, 64);

        trace(BufferUtils.toDetailString(b3));
        assertTrue(b2 != b3);
        assertEquals(64, b3.capacity());
        assertEquals("Cruel", BufferUtils.toString(b3));
        assertEquals(0, b3.arrayOffset());

    }

    //     private void testWriteToWithBufferThatDoesNotExposeArray(int capacity) {
    //         ByteArrayOutputStream out = new ByteArrayOutputStream();
    //         byte[] bytes = new byte[capacity];
    //         ThreadLocalRandom.current().nextBytes(bytes);
    //         ByteBuffer buffer = BufferUtils.allocate(capacity);
    //         BufferUtils.append(buffer, bytes, 0, capacity);
    //         BufferUtils.writeTo(buffer.asReadOnlyBuffer(), out);
    //         assertThat("Bytes in out equal bytes in buffer", Arrays.equals(bytes, out.toByteArray()), is(true));
    //     }

    //     @Test
    //     void testMappedFile() {
    //         string data = "Now is the time for all good men to come to the aid of the party";
    //         File file = File.createTempFile("test", ".txt");
    //         file.deleteOnExit();
    //         try (FileWriter out = new FileWriter(file);) {
    //             out.write(data);
    //         }

    //         ByteBuffer mapped = BufferUtils.toMappedBuffer(file);
    //         assertEquals(data, BufferUtils.toString(mapped));
    //         assertTrue(BufferUtils.isMappedBuffer(mapped));

    //         ByteBuffer direct = BufferUtils.allocateDirect(data.length());
    //         BufferUtils.clearToFill(direct);
    //         direct.put(data.getBytes(StandardCharsets.ISO_8859_1));
    //         BufferUtils.flipToFlush(direct, 0);
    //         assertEquals(data, BufferUtils.toString(direct));
    //         assertFalse(BufferUtils.isMappedBuffer(direct));

    //         ByteBuffer slice = direct.slice();
    //         assertEquals(data, BufferUtils.toString(slice));
    //         assertFalse(BufferUtils.isMappedBuffer(slice));

    //         ByteBuffer duplicate = direct.duplicate();
    //         assertEquals(data, BufferUtils.toString(duplicate));
    //         assertFalse(BufferUtils.isMappedBuffer(duplicate));

    //         ByteBuffer readonly = direct.asReadOnlyBuffer();
    //         assertEquals(data, BufferUtils.toString(readonly));
    //         assertFalse(BufferUtils.isMappedBuffer(readonly));
    //     }

    //     @Test
    //     void testNormalizeCapacity() {
    //         Assert.assertThat(BufferUtils.normalizeBufferSize(5), is(1024));
    //         Assert.assertThat(BufferUtils.normalizeBufferSize(1023), is(1024));
    //         Assert.assertThat(BufferUtils.normalizeBufferSize(1024), is(1024));
    //         Assert.assertThat(BufferUtils.normalizeBufferSize(70), is(1024));
    //         Assert.assertThat(BufferUtils.normalizeBufferSize(1025), is(1024 * 2));
    //         Assert.assertThat(BufferUtils.normalizeBufferSize(1900), is(1024 * 2));
    //         Assert.assertThat(BufferUtils.normalizeBufferSize(2048), is(1024 * 2));
    //         Assert.assertThat(BufferUtils.normalizeBufferSize(2049), is(1024 * 3));
    //         Assert.assertThat(BufferUtils.normalizeBufferSize(5000), is(1024 * 5));
    //     }

    //     @Test
    //     void testSplit() {
    //         ByteBuffer buffer = ByteBuffer.allocate(35);
    //         for (byte i = 0; i < 35; i++) {
    //             buffer.put(i);
    //         }
    //         buffer.flip();
    //         List<ByteBuffer> list = BufferUtils.split(buffer, 35);
    //         assertEquals(list.size(), 1);
    //         assertEquals(list.get(0), buffer);

    //         list = BufferUtils.split(buffer, 10);
    //         assertEquals(list.size(), 4);
    //         assertEquals(list.get(0).remaining(), 10);
    //         assertEquals(list.get(3).remaining(), 5);
    //         assertEquals(list.get(3).get(4), 34);

    //         assertEquals(buffer.position(), 0);
    //     }
}
