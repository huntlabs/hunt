module hunt.security.util.DerIndefLenConverter;

import hunt.container.ArrayList;

import hunt.util.exception;


/**
 * A package private utility class to convert indefinite length DER
 * encoded byte arrays to definite length DER encoded byte arrays.
 *
 * This assumes that the basic data structure is "tag, length, value"
 * triplet. In the case where the length is "indefinite", terminating
 * end-of-contents bytes are expected.
 *
 * @author Hemma Prafullchandra
 */
class DerIndefLenConverter {

    private enum int TAG_MASK            = 0x1f; // bits 5-1
    private enum int FORM_MASK           = 0x20; // bits 6
    private enum int CLASS_MASK          = 0xC0; // bits 8 and 7

    private enum int LEN_LONG            = 0x80; // bit 8 set
    private enum int LEN_MASK            = 0x7f; // bits 7 - 1
    private enum int SKIP_EOC_BYTES      = 2;

    private byte[] data, newData;
    private int newDataPos, dataPos, dataSize, index;
    private int unresolved = 0;

    private ArrayList!int ndefsList;

    private int numOfTotalLenBytes = 0;

    private bool isEOC(int tag) {
        return (((tag & TAG_MASK) == 0x00) &&  // EOC
                ((tag & FORM_MASK) == 0x00) && // primitive
                ((tag & CLASS_MASK) == 0x00)); // universal
    }

    // if bit 8 is set then it implies either indefinite length or long form
    static bool isLongForm(int lengthByte) {
        return ((lengthByte & LEN_LONG) == LEN_LONG);
    }

    /*
     * Default package private constructor
     */
    this() { 
        ndefsList = new ArrayList!int();
    }

    /**
     * Checks whether the given length byte is of the form
     * <em>Indefinite</em>.
     *
     * @param lengthByte the length byte from a DER encoded
     *        object.
     * @return true if the byte is of Indefinite form otherwise
     *         returns false.
     */
    static bool isIndefinite(int lengthByte) {
        return (isLongForm(lengthByte) && ((lengthByte & LEN_MASK) == 0));
    }

    /**
     * Parse the tag and if it is an end-of-contents tag then
     * add the current position to the <code>eocList</code> vector.
     */
    private void parseTag() {
        if (dataPos == dataSize)
            return;
        // if (isEOC(data[dataPos]) && (data[dataPos + 1] == 0)) {
        //     int numOfEncapsulatedLenBytes = 0;
        //     T elem = null;
        //     int index;
        //     for (index = ndefsList.size()-1; index >= 0; index--) {
        //         // Determine the first element in the vector that does not
        //         // have a matching EOC
        //         elem = ndefsList.get(index);
        //         static if(is(T == int)) {
        //             break;
        //         } else {
        //             numOfEncapsulatedLenBytes += (cast(byte[])elem).length - 3;
        //         }
        //     }
        //     if (index < 0) {
        //         throw new IOException("EOC does not have matching " +
        //                               "indefinite-length tag");
        //     }
        //     int sectionLen = dataPos - (cast(int)elem).intValue() +
        //                      numOfEncapsulatedLenBytes;
        //     byte[] sectionLenBytes = getLengthBytes(sectionLen);
        //     ndefsList.set(index, sectionLenBytes);
        //     unresolved--;

        //     // Add the number of bytes required to represent this section
        //     // to the total number of length bytes,
        //     // and subtract the indefinite-length tag (1 byte) and
        //     // EOC bytes (2 bytes) for this section
        //     numOfTotalLenBytes += (sectionLenBytes.length - 3);
        // }
        dataPos++;
        
        implementationMissing();
    }

    /**
     * Write the tag and if it is an end-of-contents tag
     * then skip the tag and its 1 byte length of zero.
     */
    private void writeTag() {
        if (dataPos == dataSize)
            return;
        int tag = data[dataPos++];
        if (isEOC(tag) && (data[dataPos] == 0)) {
            dataPos++;  // skip length
            writeTag();
        } else
            newData[newDataPos++] = cast(byte)tag;
    }

    /**
     * Parse the length and if it is an indefinite length then add
     * the current position to the <code>ndefsList</code> vector.
     */
    private int parseLength() {
        int curLen = 0;
        if (dataPos == dataSize)
            return curLen;
        int lenByte = data[dataPos++] & 0xff;
        if (isIndefinite(lenByte)) {
            ndefsList.add(dataPos);
            unresolved++;
            return curLen;
        }
        if (isLongForm(lenByte)) {
            lenByte &= LEN_MASK;
            if (lenByte > 4) {
                throw new IOException("Too much data");
            }
            if ((dataSize - dataPos) < (lenByte + 1)) {
                throw new IOException("Too little data");
            }
            for (int i = 0; i < lenByte; i++) {
                curLen = (curLen << 8) + (data[dataPos++] & 0xff);
            }
            if (curLen < 0) {
                throw new IOException("Invalid length bytes");
            }
        } else {
           curLen = (lenByte & LEN_MASK);
        }
        return curLen;
    }

    /**
     * Write the length and if it is an indefinite length
     * then calculate the definite length from the positions
     * of the indefinite length and its matching EOC terminator.
     * Then, write the value.
     */
    private void writeLengthAndValue() {
        if (dataPos == dataSize)
           return;
        // int curLen = 0;
        // int lenByte = data[dataPos++] & 0xff;
        // if (isIndefinite(lenByte)) {
        //     byte[] lenBytes = cast(byte[])ndefsList.get(index++);
        //     System.arraycopy(lenBytes, 0, newData, newDataPos,
        //                      lenBytes.length);
        //     newDataPos += lenBytes.length;
        //     return;
        // }
        // if (isLongForm(lenByte)) {
        //     lenByte &= LEN_MASK;
        //     for (int i = 0; i < lenByte; i++) {
        //         curLen = (curLen << 8) + (data[dataPos++] & 0xff);
        //     }
        //     if (curLen < 0) {
        //         throw new IOException("Invalid length bytes");
        //     }
        // } else {
        //     curLen = (lenByte & LEN_MASK);
        // }
        // writeLength(curLen);
        // writeValue(curLen);
        implementationMissing();
    }

    private void writeLength(int curLen) {
        if (curLen < 128) {
            newData[newDataPos++] = cast(byte)curLen;

        } else if (curLen < (1 << 8)) {
            newData[newDataPos++] = cast(byte)0x81;
            newData[newDataPos++] = cast(byte)curLen;

        } else if (curLen < (1 << 16)) {
            newData[newDataPos++] = cast(byte)0x82;
            newData[newDataPos++] = cast(byte)(curLen >> 8);
            newData[newDataPos++] = cast(byte)curLen;

        } else if (curLen < (1 << 24)) {
            newData[newDataPos++] = cast(byte)0x83;
            newData[newDataPos++] = cast(byte)(curLen >> 16);
            newData[newDataPos++] = cast(byte)(curLen >> 8);
            newData[newDataPos++] = cast(byte)curLen;

        } else {
            newData[newDataPos++] = cast(byte)0x84;
            newData[newDataPos++] = cast(byte)(curLen >> 24);
            newData[newDataPos++] = cast(byte)(curLen >> 16);
            newData[newDataPos++] = cast(byte)(curLen >> 8);
            newData[newDataPos++] = cast(byte)curLen;
        }
    }

    private byte[] getLengthBytes(int curLen) {
        byte[] lenBytes;
        int index = 0;

        if (curLen < 128) {
            lenBytes = new byte[1];
            lenBytes[index++] = cast(byte)curLen;

        } else if (curLen < (1 << 8)) {
            lenBytes = new byte[2];
            lenBytes[index++] = cast(byte)0x81;
            lenBytes[index++] = cast(byte)curLen;

        } else if (curLen < (1 << 16)) {
            lenBytes = new byte[3];
            lenBytes[index++] = cast(byte)0x82;
            lenBytes[index++] = cast(byte)(curLen >> 8);
            lenBytes[index++] = cast(byte)curLen;

        } else if (curLen < (1 << 24)) {
            lenBytes = new byte[4];
            lenBytes[index++] = cast(byte)0x83;
            lenBytes[index++] = cast(byte)(curLen >> 16);
            lenBytes[index++] = cast(byte)(curLen >> 8);
            lenBytes[index++] = cast(byte)curLen;

        } else {
            lenBytes = new byte[5];
            lenBytes[index++] = cast(byte)0x84;
            lenBytes[index++] = cast(byte)(curLen >> 24);
            lenBytes[index++] = cast(byte)(curLen >> 16);
            lenBytes[index++] = cast(byte)(curLen >> 8);
            lenBytes[index++] = cast(byte)curLen;
        }

        return lenBytes;
    }

    // Returns the number of bytes needed to represent the given length
    // in ASN.1 notation
    private int getNumOfLenBytes(int len) {
        int numOfLenBytes = 0;

        if (len < 128) {
            numOfLenBytes = 1;
        } else if (len < (1 << 8)) {
            numOfLenBytes = 2;
        } else if (len < (1 << 16)) {
            numOfLenBytes = 3;
        } else if (len < (1 << 24)) {
            numOfLenBytes = 4;
        } else {
            numOfLenBytes = 5;
        }
        return numOfLenBytes;
    }

    /**
     * Parse the value;
     */
    private void parseValue(int curLen) {
        dataPos += curLen;
    }

    /**
     * Write the value;
     */
    private void writeValue(int curLen) {
        for (int i=0; i < curLen; i++)
            newData[newDataPos++] = data[dataPos++];
    }

    /**
     * Converts a indefinite length DER encoded byte array to
     * a definte length DER encoding.
     *
     * @param indefData the byte array holding the indefinite
     *        length encoding.
     * @return the byte array containing the definite length
     *         DER encoding.
     * @exception IOException on parsing or re-writing errors.
     */
    byte[] convert(byte[] indefData) {
        data = indefData;
        dataPos=0; index=0;
        dataSize = data.length;
        int len=0;
        int unused = 0;

        // parse and set up the vectors of all the indefinite-lengths
        while (dataPos < dataSize) {
            parseTag();
            len = parseLength();
            parseValue(len);
            if (unresolved == 0) {
                unused = dataSize - dataPos;
                dataSize = dataPos;
                break;
            }
        }

        if (unresolved != 0) {
            throw new IOException("not all indef len BER resolved");
        }

        newData = new byte[dataSize + numOfTotalLenBytes + unused];
        dataPos=0; newDataPos=0; index=0;

        // write out the new byte array replacing all the indefinite-lengths
        // and EOCs
        while (dataPos < dataSize) {
           writeTag();
           writeLengthAndValue();
        }

        int startIndex = dataSize + numOfTotalLenBytes;
        int endIndex = startIndex + unused;
        newData[startIndex .. endIndex] = indefData[dataSize .. dataSize + unused];
        // System.arraycopy(indefData, dataSize,
        //                  newData, dataSize + numOfTotalLenBytes, unused);

        return newData;
    }
}
