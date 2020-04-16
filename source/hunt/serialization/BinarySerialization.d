module hunt.serialization.BinarySerialization;

import hunt.serialization.BinarySerializer;
import hunt.serialization.BinaryDeserializer;

ubyte[] serialize(T)(T obj) {
    auto serializer = BinarySerializer();
    return serializer.oArchive(obj);
}

T unserialize(T)(ubyte[] buffer) {
    auto deserializer = BinaryDeserializer(buffer);
    return deserializer.iArchive!T;
}


alias toObject = unserialize;
alias toBinary = serialize;