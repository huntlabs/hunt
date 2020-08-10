module hunt.serialization.BinarySerialization;

import hunt.serialization.BinarySerializer;
import hunt.serialization.BinaryDeserializer;
import hunt.serialization.Common;

import std.traits;

ubyte[] serialize(SerializationOptions options = SerializationOptions.Full, T)(T obj) {
    auto serializer = BinarySerializer();
    return serializer.oArchive!(options)(obj);
}

T unserialize(T, SerializationOptions options = SerializationOptions.Full)(ubyte[] buffer) {
    auto deserializer = BinaryDeserializer(buffer);
    return deserializer.iArchive!(options, T);
}


alias toObject = unserialize;
alias toBinary = serialize;