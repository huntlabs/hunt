module test.ConverterUtilsTest;

import hunt.util.ConverterUtils;

import hunt.Assert;
import hunt.Exceptions;
import hunt.logging.ConsoleLogger;

import std.format;

class ConverterUtilsTest {

    void testFromHexString() {
        string str = "7b226a6f6244657461696c31223a226a6f6227732064617461227d";
        
        byte[] data = ConverterUtils.fromHexString(str);
        string s = format("%(%02x%)", data);
        assert(s == str);
        assert(`{"jobDetail1":"job's data"}` == cast(string)data);

        // tracef("%(%02X %)", data);
    }
}
