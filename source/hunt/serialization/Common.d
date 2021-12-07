module hunt.serialization.Common;

import std.typecons : Flag;


/**
 * 
 */
struct SerializationOptions {
    enum Default = SerializationOptions();
    enum Full = SerializationOptions().includeMeta(true);
    enum Lite = SerializationOptions().traverseBase(false).ignoreNull(true).depth(0);
    enum Normal = SerializationOptions().ignoreNull(true);

    enum OnlyPublicWithNull = SerializationOptions().onlyPublic(true).traverseBase(false).depth(0);
    enum OnlyPublicLite = OnlyPublicWithNull.ignoreNull(true);

    private bool _onlyPublic = false;

    private bool _traverseBase = true;

    private bool _includeMeta = false;

    private bool _ignoreNull = false;

    private bool _canThrow = true;
    
    private bool _canCircularDetect = true;  // Circular Reference Detect

    private int _depth = -1;

/* --------------------------------------------------- properties --------------------------------------------------- */

    bool onlyPublic() { return _onlyPublic; }

    SerializationOptions onlyPublic(bool flag) {
        SerializationOptions r = this;
        r._onlyPublic = flag;
        return r;
    }

    bool traverseBase() { return _traverseBase; }

    SerializationOptions traverseBase(bool flag) {
        SerializationOptions r = this;
        r._traverseBase = flag;
        return r;
    }

    bool includeMeta() { return _includeMeta; }

    SerializationOptions includeMeta(bool flag) {
        SerializationOptions r = this;
        r._includeMeta = flag;
        return r;
    }

    bool ignoreNull() { return _ignoreNull; }

    SerializationOptions ignoreNull(bool flag) {
        SerializationOptions r = this;
        r._ignoreNull = flag;
        return r;
    }

    bool canThrow() { return _canThrow; }

    SerializationOptions canThrow(bool flag) {
        SerializationOptions r = this;
        r._canThrow = flag;
        return r;
    }

    bool canCircularDetect() { return _canCircularDetect; }

    SerializationOptions canCircularDetect(bool flag) {
        SerializationOptions r = this;
        r._canCircularDetect = flag;
        return r;
    }

    int depth() { return _depth; }

    SerializationOptions depth(int depth) {
        SerializationOptions r = this;
        r._depth = depth;
        return r;
    }
}

/**
   Flag indicating whether to traverse the base class.
*/
alias TraverseBase = Flag!"traverseBase";

/**
   Flag indicating whether to allow the public member only.
*/
alias OnlyPublic = Flag!"onlyPublic";

/**
   Flag indicating whether to include the meta data (especially for a class or an interface).
*/
alias IncludeMeta = Flag!"includeMeta";

/**
   Flag indicating whether to ignore the null member.
*/
alias IgnoreNull = Flag!"ignoreNull";


/// attributes for json
/// https://dzone.com/articles/jackson-annotations-for-json-part-2-serialization

/**
 * Excludes the field from both encoding and decoding.
 */
enum Ignore;

deprecated("Using Ignore instead.")
alias Exclude = Ignore;

/**
 * Includes this even if it would otherwise be excluded.
 * If Exclude (or other UDA(@)) and Include are present value will be included.
 * Can also be used on @property methods to include them. (Be sure both the setter and getter exist!)
 * If used on a value of a base class value will be included.
 */
enum Include;

/**
 * Excludes the field from decoding, encode only.
 */
enum EncodeOnly;

/**
 * Excludes the field from encoding, decode only.
 */
enum DecodeOnly;