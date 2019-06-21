module hunt.serialization.Common;

import std.typecons : Flag;


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



// alias OnlyPublic = Flag!"onlyPublic";


/// attributes for json
/// https://dzone.com/articles/jackson-annotations-for-json-part-2-serialization

/**
 * Excludes the field from both encoding and decoding.
 */
enum Exclude;

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