/**
 * Copyright: Copyright Jason White, 2015-2016
 * License:   MIT
 * Authors:   Jason White
 *
 * Description:
 * Parses arguments.
 *
 * TODO:
 *  - Handle bundled options
 */
module hunt.util.darg;

/**
 * Generic argument parsing exception.
 */
class ArgParseError : Exception
{
    /**
     */
    this(string msg) pure nothrow
    {
        super(msg);
    }
}

/**
 * Thrown when help is requested.
 */
class ArgParseHelp : Exception
{
    this(string msg) pure nothrow
    {
        super(msg);
    }
}

/**
 * User defined attribute for an option.
 */
struct Option
{
    /// List of names the option can have.
    string[] names;

    /**
     * Constructs the option with a list of names. Note that any leading "-" or
     * "--" should be omitted. This is added automatically depending on the
     * length of the name.
     */
    this(string[] names...) pure nothrow
    {
        this.names = names;
    }

    /**
     * Returns true if the given option name is equivalent to this option.
     */
    bool opEquals(string opt) const pure nothrow
    {
        foreach (name; names)
        {
            if (name == opt)
                return true;
        }

        return false;
    }

    unittest
    {
        static assert(Option("foo") == "foo");
        static assert(Option("foo", "f") == "foo");
        static assert(Option("foo", "f") == "f");
        static assert(Option("foo", "bar", "baz") == "foo");
        static assert(Option("foo", "bar", "baz") == "bar");
        static assert(Option("foo", "bar", "baz") == "baz");

        static assert(Option("foo", "bar") != "baz");
    }

    /**
     * Returns the canonical name of this option. That is, its first name.
     */
    string toString() const pure nothrow
    {
        return names.length > 0 ? (nameToOption(names[0])) : null;
    }

    unittest
    {
        static assert(Option().toString is null);
        static assert(Option("foo", "bar", "baz").toString == "--foo");
        static assert(Option("f", "bar", "baz").toString == "-f");
    }
}

/**
 * An option flag. These types of options are handled specially and never have
 * an argument.
 */
enum OptionFlag : bool
{
    /// The option flag was not specified.
    no = false,

    /// The option flag was specified.
    yes = true,
}

/**
 * Multiplicity of an argument.
 */
enum Multiplicity
{
    optional,
    zeroOrMore,
    oneOrMore,
}

/**
 * User defined attribute for a positional argument.
 */
struct Argument
{
    /**
     * Name of the argument. Since this is a positional argument, this value is
     * only used in the help string.
     */
    string name;

    /**
     * Lower and upper bounds for the number of values this argument can have.
     */
    size_t lowerBound = 1;

    /// Ditto
    size_t upperBound = 1;

    /**
     * Constructs an argument with the given name and count. The count specifies
     * how many argument elements should be consumed from the command line. By
     * default, this is 1.
     */
    this(string name, size_t count = 1) pure nothrow
    body
    {
        this.name = name;
        this.lowerBound = count;
        this.upperBound = count;
    }

    /**
     * Constructs an argument with the given name and an upper and lower bound
     * for how many argument elements should be consumed from the command line.
     */
    this(string name, size_t lowerBound, size_t upperBound) pure nothrow
    in { assert(lowerBound < upperBound); }
    body
    {
        this.name = name;
        this.lowerBound = lowerBound;
        this.upperBound = upperBound;
    }

    /**
     * An argument with a multiplicity specifier.
     */
    this(string name, Multiplicity multiplicity) pure nothrow
    {
        this.name = name;

        final switch (multiplicity)
        {
            case Multiplicity.optional:
                this.lowerBound = 0;
                this.upperBound = 1;
                break;
            case Multiplicity.zeroOrMore:
                this.lowerBound = 0;
                this.upperBound = size_t.max;
                break;
            case Multiplicity.oneOrMore:
                this.lowerBound = 1;
                this.upperBound = size_t.max;
                break;
        }
    }

    /**
     * Convert to a usage string.
     */
    @property string usage() const pure
    {
        import std.format : format;

        if (lowerBound == 0)
        {
            if (upperBound == 1)
                return "["~ name ~"]";
            else if (upperBound == upperBound.max)
                return "["~ name ~"...]";

            return "["~ name ~"... (up to %d times)]".format(upperBound);
        }
        else if (lowerBound == 1)
        {
            if (upperBound == 1)
                return name;
            else if (upperBound == upperBound.max)
                return name ~ " ["~ name ~"...]";

            return name ~ " ["~ name ~"... (up to %d times)]"
                .format(upperBound-1);
        }

        if (lowerBound == upperBound)
            return name ~" (multiplicity of %d)"
                .format(upperBound);

        return name ~" ["~ name ~"... (between %d and %d times)]"
            .format(lowerBound-1, upperBound-1);
    }

    /**
     * Get a multiplicity error string.
     *
     * Params:
     *   specified = The number of parameters that were specified.
     *
     * Returns:
     * If there is an error, returns a string explaining the error. Otherwise,
     * returns $(D null).
     */
    @property string multiplicityError(size_t specified) const pure
    {
        import std.format : format;

        if (specified >= lowerBound && specified <= upperBound)
            return null;

        if (specified < lowerBound)
        {
            if (lowerBound == 1 && upperBound == 1)
                return "Expected a value for positional argument '%s'"
                    .format(name);
            else
                return ("Expected at least %d values for positional argument" ~
                    " '%s'. Only %d values were specified.")
                    .format(lowerBound, name, specified);
        }

        // This should never happen. Argument parsing is not greedy.
        return "Too many values specified for positional argument '%s'.";
    }
}

unittest
{
    with (Argument("lion"))
    {
        assert(name == "lion");
        assert(lowerBound == 1);
        assert(upperBound == 1);
    }

    with (Argument("tiger", Multiplicity.optional))
    {
        assert(lowerBound == 0);
        assert(upperBound == 1);
    }

    with (Argument("bear", Multiplicity.zeroOrMore))
    {
        assert(lowerBound == 0);
        assert(upperBound == size_t.max);
    }

    with (Argument("dinosaur", Multiplicity.oneOrMore))
    {
        assert(lowerBound == 1);
        assert(upperBound == size_t.max);
    }
}

/**
 * Help string for an option or positional argument.
 */
struct Help
{
    /// Help string.
    string help;
}

/**
 * Meta variable name.
 */
struct MetaVar
{
    /// Name of the meta variable.
    string name;
}

/**
 * Function signatures that can handle arguments or options.
 */
private alias void OptionHandler() pure;
private alias void ArgumentHandler(string) pure; /// Ditto

template isOptionHandler(Func)
{
    import std.meta : AliasSeq;
    import std.traits : arity, hasFunctionAttributes, isFunction, ReturnType;

    static if (isFunction!Func)
    {
        enum isOptionHandler =
            hasFunctionAttributes!(Func, "pure") &&
            is(ReturnType!Func == void) &&
            arity!Func == 0;
    }
    else
    {
        enum isOptionHandler = false;
    }
}

template isArgumentHandler(Func)
{
    import std.meta : AliasSeq;
    import std.traits : hasFunctionAttributes, isFunction, Parameters, ReturnType;

    static if (isFunction!Func)
    {
        enum isArgumentHandler =
            hasFunctionAttributes!(Func, "pure") &&
            is(ReturnType!Func == void) &&
            is(Parameters!Func == AliasSeq!(string));
    }
    else
    {
        enum isArgumentHandler = false;
    }
}

unittest
{
    struct TemplateOptions(T)
    {
        void optionHandler() pure { }
        void argumentHandler(string) pure { }
        string foo() pure { return ""; }
        void bar() { import std.stdio : writeln; writeln("bar"); }
        void baz(int) pure { }
    }

    TemplateOptions!int options;

    static assert(!is(typeof(options.optionHandler) : OptionHandler));
    static assert(!is(typeof(options.argumentHandler) : ArgumentHandler));
    static assert(!is(typeof(options.foo) : ArgumentHandler));
    static assert(!is(typeof(options.bar) : ArgumentHandler));
    static assert(!is(typeof(options.baz) : ArgumentHandler));

    static assert(isOptionHandler!(typeof(options.optionHandler)));
    static assert(!isOptionHandler!(typeof(options.argumentHandler)));
    static assert(!isOptionHandler!(typeof(options.foo)));
    static assert(!isOptionHandler!(typeof(options.bar)));
    static assert(!isOptionHandler!(typeof(options.baz)));

    static assert(!isArgumentHandler!(typeof(options.optionHandler)));
    static assert(isArgumentHandler!(typeof(options.argumentHandler)));
    static assert(!isArgumentHandler!(typeof(options.foo)));
    static assert(!isArgumentHandler!(typeof(options.bar)));
    static assert(!isArgumentHandler!(typeof(options.baz)));
}

/**
 * Returns true if the given argument is a short option. That is, if it starts
 * with a '-'.
 */
bool isShortOption(string arg) pure nothrow
{
    return arg.length > 1 && arg[0] == '-' && arg[1] != '-';
}

unittest
{
    static assert(!isShortOption(""));
    static assert(!isShortOption("-"));
    static assert(!isShortOption("a"));
    static assert(!isShortOption("ab"));
    static assert( isShortOption("-a"));
    static assert( isShortOption("-ab"));
    static assert(!isShortOption("--a"));
    static assert(!isShortOption("--abc"));
}

/**
 * Returns true if the given argument is a long option. That is, if it starts
 * with "--".
 */
bool isLongOption(string arg) pure nothrow
{
    return arg.length > 2 && arg[0 .. 2] == "--" && arg[2] != '-';
}

unittest
{
    static assert(!isLongOption(""));
    static assert(!isLongOption("a"));
    static assert(!isLongOption("ab"));
    static assert(!isLongOption("abc"));
    static assert(!isLongOption("-"));
    static assert(!isLongOption("-a"));
    static assert(!isLongOption("--"));
    static assert( isLongOption("--a"));
    static assert( isLongOption("--arg"));
    static assert( isLongOption("--arg=asdf"));
}

/**
 * Returns true if the given argument is an option. That is, it is either a
 * short option or a long option.
 */
bool isOption(string arg) pure nothrow
{
    return isShortOption(arg) || isLongOption(arg);
}

private static struct OptionSplit
{
    string head;
    string tail;
}

/**
 * Splits an option on "=".
 */
private auto splitOption(string option) pure
{
    size_t i = 0;
    while (i < option.length && option[i] != '=')
        ++i;

    return OptionSplit(
            option[0 .. i],
            (i < option.length) ? option[i+1 .. $] : null
            );
}

unittest
{
    static assert(splitOption("") == OptionSplit("", null));
    static assert(splitOption("--foo") == OptionSplit("--foo", null));
    static assert(splitOption("--foo=") == OptionSplit("--foo", ""));
    static assert(splitOption("--foo=bar") == OptionSplit("--foo", "bar"));
}

private static struct ArgSplit
{
    const(string)[] head;
    const(string)[] tail;
}

/**
 * Splits arguments on "--".
 */
private auto splitArgs(const(string)[] args) pure
{
    size_t i = 0;
    while (i < args.length && args[i] != "--")
        ++i;

    return ArgSplit(
            args[0 .. i],
            (i < args.length) ? args[i+1 .. $] : []
            );
}

unittest
{
    static assert(splitArgs([]) == ArgSplit([], []));
    static assert(splitArgs(["a", "b"]) == ArgSplit(["a", "b"], []));
    static assert(splitArgs(["a", "--"]) == ArgSplit(["a"], []));
    static assert(splitArgs(["a", "--", "b"]) == ArgSplit(["a"], ["b"]));
    static assert(splitArgs(["a", "--", "b", "c"]) == ArgSplit(["a"], ["b", "c"]));
}

/**
 * Returns an option name without the leading ("--" or "-"). If it is not an
 * option, returns null.
 */
private string optionToName(string option) pure nothrow
{
    if (isLongOption(option))
        return option[2 .. $];

    if (isShortOption(option))
        return option[1 .. $];

    return null;
}

unittest
{
    static assert(optionToName("--opt") == "opt");
    static assert(optionToName("-opt") == "opt");
    static assert(optionToName("-o") == "o");
    static assert(optionToName("opt") is null);
    static assert(optionToName("o") is null);
    static assert(optionToName("") is null);
}

/**
 * Returns the appropriate long or short option corresponding to the given name.
 */
private string nameToOption(string name) pure nothrow
{
    switch (name.length)
    {
        case 0:
            return null;
        case 1:
            return "-" ~ name;
        default:
            return "--" ~ name;
    }
}

unittest
{
    static assert(nameToOption("opt") == "--opt");
    static assert(nameToOption("o") == "-o");
    static assert(nameToOption("") is null);
}

unittest
{
    immutable identities = ["opt", "o", ""];

    foreach (identity; identities)
        assert(identity.nameToOption.optionToName == identity);
}

/**
 * Check if the given type is valid for an option.
 */
private template isValidOptionType(T)
{
    import std.traits : isBasicType, isSomeString;

    static if (isBasicType!T ||
               isSomeString!T ||
               isOptionHandler!T ||
               isArgumentHandler!T
        )
    {
        enum isValidOptionType = true;
    }
    else static if (is(T A : A[]))
    {
        enum isValidOptionType = isValidOptionType!A;
    }
    else
    {
        enum isValidOptionType = false;
    }
}

unittest
{
    static assert(isValidOptionType!bool);
    static assert(isValidOptionType!int);
    static assert(isValidOptionType!float);
    static assert(isValidOptionType!char);
    static assert(isValidOptionType!string);
    static assert(isValidOptionType!(int[]));

    alias void Func1() pure;
    alias void Func2(string) pure;
    alias int Func3();
    alias int Func4(string);
    alias void Func5();
    alias void Func6(string);

    static assert(isValidOptionType!Func1);
    static assert(isValidOptionType!Func2);
    static assert(!isValidOptionType!Func3);
    static assert(!isValidOptionType!Func4);
    static assert(!isValidOptionType!Func5);
    static assert(!isValidOptionType!Func6);
}

/**
 * Count the number of positional arguments.
 */
size_t countArgs(Options)() pure nothrow
{
    import std.meta : Alias;
    import std.traits : getUDAs;
    import std.algorithm.comparison : min;

    size_t count = 0;

    foreach (member; __traits(allMembers, Options))
    {
        alias symbol = Alias!(__traits(getMember, Options, member));
        alias argUDAs = getUDAs!(symbol, Argument);
        count += min(argUDAs.length, 1);
    }

    return count;
}

/**
 * Count the number of options.
 */
size_t countOpts(Options)() pure nothrow
{
    import std.meta : Alias;
    import std.traits : getUDAs;
    import std.algorithm.comparison : min;

    size_t count = 0;

    foreach (member; __traits(allMembers, Options))
    {
        alias symbol = Alias!(__traits(getMember, Options, member));
        alias optUDAs = getUDAs!(symbol, Option);
        count += min(optUDAs.length, 1);
    }

    return count;
}

unittest
{
    static struct A {}

    static assert(countArgs!A == 0);
    static assert(countOpts!A == 0);

    static struct B
    {
        @Argument("test1")
        string test1;
        @Argument("test2")
        string test2;

        @Option("test3", "test3a")
        @Option("test3b", "test3c")
        string test3;
    }

    static assert(countArgs!B == 2);
    static assert(countOpts!B == 1);

    static struct C
    {
        string test;

        @Argument("test1")
        string test1;

        @Argument("test2")
        @Argument("test2a")
        string test2;

        @Option("test3")
        string test3;

        @Option("test4")
        string test4;
    }

    static assert(countArgs!C == 2);
    static assert(countOpts!C == 2);
}

/**
 * Checks if the given options are valid.
 */
private void validateOptions(Options)() pure nothrow
{
    import std.meta : Alias;
    import std.traits : getUDAs, fullyQualifiedName;

    foreach (member; __traits(allMembers, Options))
    {
        alias symbol = Alias!(__traits(getMember, Options, member));
        alias optUDAs = getUDAs!(symbol, Option);
        alias argUDAs = getUDAs!(symbol, Argument);

        // Basic error checking
        static assert(!(optUDAs.length > 0 && argUDAs.length > 0),
            fullyQualifiedName!symbol ~" cannot be both an Option and an Argument"
            );
        static assert(optUDAs.length <= 1,
            fullyQualifiedName!symbol ~" cannot have multiple Option attributes"
            );
        static assert(argUDAs.length <= 1,
            fullyQualifiedName!symbol ~" cannot have multiple Argument attributes"
            );

        static if (argUDAs.length > 0)
            static assert(isValidOptionType!(typeof(symbol)),
                fullyQualifiedName!symbol ~" is not a valid Argument type"
                );

        static if (optUDAs.length > 0)
            static assert(isValidOptionType!(typeof(symbol)),
                fullyQualifiedName!symbol ~" is not a valid Option type"
                );
    }
}

/**
 * Checks if the given option type has an associated argument. Currently, only
 * an OptionFlag does not have an argument.
 */
private template hasArgument(T)
{
    static if (is(T : OptionFlag) || isOptionHandler!T)
        enum hasArgument = false;
    else
        enum hasArgument = true;
}

unittest
{
    static assert(hasArgument!string);
    static assert(hasArgument!ArgumentHandler);
    static assert(hasArgument!int);
    static assert(hasArgument!bool);
    static assert(!hasArgument!OptionFlag);
    static assert(!hasArgument!OptionHandler);
}

/**
 * Parses an argument.
 *
 * Throws: ArgParseError if the given argument cannot be converted to the
 * requested type.
 */
T parseArg(T)(string arg) pure
{
    import std.conv : to, ConvException;

    try
    {
        return to!T(arg);
    }
    catch (ConvException e)
    {
        throw new ArgParseError(e.msg);
    }
}

unittest
{
    import std.exception : ce = collectException;

    assert(parseArg!int("42") == 42);
    assert(parseArg!string("42") == "42");
    assert(ce!ArgParseError(parseArg!size_t("-42")));
}

/**
 * Returns the canonical name of the given member's argument. If there is no
 * argument for the given member, null is returned.
 */
private string argumentName(Options, string member)() pure
{
    import std.meta : Alias;
    import std.traits : getUDAs;
    import std.string : toUpper;

    alias symbol = Alias!(__traits(getMember, Options, member));

    static if (hasArgument!(typeof(symbol)))
    {
        alias metavar = getUDAs!(symbol, MetaVar);
        static if (metavar.length > 0)
            return metavar[0].name;
        else static if (isArgumentHandler!(typeof(symbol)))
            return member.toUpper;
        else
            return "<"~ typeof(symbol).stringof ~ ">";
    }
    else
    {
        return null;
    }
}

unittest
{
    static struct Options
    {
        @Option("test1")
        OptionFlag test1;

        @Option("test2")
        string test2;

        @Option("test3")
        @MetaVar("asdf")
        string test3;

        private string _arg;

        @Option("test4")
        void test4(string arg) pure
        {
            _arg = arg;
        }

        @Option("test5")
        @MetaVar("metavar")
        void test5(string arg) pure
        {
            _arg = arg;
        }
    }

    static assert(argumentName!(Options, "test1") == null);
    static assert(argumentName!(Options, "test2") == "<string>");
    static assert(argumentName!(Options, "test3") == "asdf");
    static assert(argumentName!(Options, "test4") == "TEST4");
    static assert(argumentName!(Options, "test5") == "metavar");
}

/**
 * Constructs a printable usage string at compile time from the given options
 * structure.
 */
string usageString(Options)(string program) pure
    if (is(Options == struct))
{
    import std.meta : Alias;
    import std.traits : getUDAs;
    import std.array : replicate;
    import std.string : wrap, toUpper;

    string output = "Usage: "~ program;

    string indent = " ".replicate(output.length + 1);

    // List all options
    foreach (member; __traits(allMembers, Options))
    {
        alias symbol = Alias!(__traits(getMember, Options, member));
        alias optUDAs = getUDAs!(symbol, Option);

        static if (optUDAs.length > 0 && optUDAs[0].names.length > 0)
        {
            output ~= " ["~ nameToOption(optUDAs[0].names[0]);

            if (immutable name = argumentName!(Options, member))
                output ~= "="~ name;

            output ~= "]";
        }
    }

    // List all arguments
    foreach (member; __traits(allMembers, Options))
    {
        alias symbol = Alias!(__traits(getMember, Options, member));
        alias argUDAs = getUDAs!(symbol, Argument);

        static if (argUDAs.length > 0)
            output ~= " "~ argUDAs[0].usage;
    }

    return output.wrap(80, null, indent, 4);
}

/**
 * Generates a help string for a single argument. Returns null if the given
 * member is not an argument.
 */
private string argumentHelp(Options, string member)(size_t padding = 14) pure
{
    import std.meta : Alias;
    import std.traits : getUDAs;
    import std.array : replicate;
    import std.string : wrap;

    string output;

    alias symbol = Alias!(__traits(getMember, Options, member));
    alias argUDAs = getUDAs!(symbol, Argument);

    static if (argUDAs.length > 0)
    {
        enum name = argUDAs[0].name;
        output ~= " "~ name;

        alias helpUDAs = getUDAs!(symbol, Help);
        static if (helpUDAs.length > 0)
        {
            if (name.length > padding)
                output ~= "\n";

            immutable indent = " ".replicate(padding + 3);
            immutable firstIndent = (name.length > padding) ? indent :
                " ".replicate(padding - name.length + 2);

            output ~= helpUDAs[0].help.wrap(80, firstIndent, indent, 4);
        }
        else
        {
            output ~= "\n";
        }
    }

    return output;
}

/**
 * Generates a help string for a single option. Returns null if the given member
 * is not an option.
 */
private string optionHelp(Options, string member)(size_t padding = 14) pure
{
    import std.meta : Alias;
    import std.traits : getUDAs;
    import std.array : replicate;
    import std.string : wrap;

    string output;

    alias symbol = Alias!(__traits(getMember, Options, member));
    alias optUDAs = getUDAs!(symbol, Option);

    static if (optUDAs.length > 0)
    {
        enum names = optUDAs[0].names;
        static if (names.length > 0)
        {
            output ~= " " ~ nameToOption(names[0]);

            foreach (name; names[1 .. $])
                output ~= ", " ~ nameToOption(name);

            if (string arg = argumentName!(Options, member))
                output ~= " " ~ arg;

            immutable len = output.length;

            alias helpUDAs = getUDAs!(symbol, Help);
            static if (helpUDAs.length > 0)
            {
                immutable overflow = len > padding+1;
                if (overflow)
                    output ~= "\n";

                immutable indent = " ".replicate(padding+3);
                immutable firstIndent = overflow
                    ? indent : " ".replicate((padding + 1) - len + 2);

                output ~= helpUDAs[0].help.wrap(80, firstIndent, indent, 4);
            }
            else
            {
                output ~= "\n";
            }
        }
    }

    return output;
}

/**
 * Constructs a printable help string at compile time for the given options
 * structure.
 */
string helpString(Options)(string description = null) pure
    if (is(Options == struct))
{
    import std.format : format;
    import std.string : wrap;

    string output;

    if (description)
        output ~= description.wrap(80) ~ "\n";

    // List all positional arguments.
    static if(countArgs!Options > 0)
    {
        output ~= "Positional arguments:\n";

        foreach (member; __traits(allMembers, Options))
            output ~= argumentHelp!(Options, member);

        static if (countOpts!Options > 0)
            output ~= "\n";
    }

    // List all options
    static if (countOpts!Options > 0)
    {
        output ~= "Optional arguments:\n";

        foreach (member; __traits(allMembers, Options))
            output ~= optionHelp!(Options, member);
    }

    return output;
}

/**
 * Parsing configuration.
 */
enum Config
{
    /**
     * Enables option bundling. That is, multiple single character options can
     * be bundled together.
     */
    bundling = 1 << 0,

    /**
     * Ignore unknown options. These are then parsed as positional arguments.
     */
    ignoreUnknown = 1 << 1,

    /**
     * Throw the ArgParseHelp exception when the option "help" is specified.
     * This requires the option to exist in the options struct.
     */
    handleHelp = 1 << 2,

    /**
     * Default configuration options.
     */
    default_ = bundling | handleHelp,
}

/**
 * Parses options from the given list of arguments. Note that the first argument
 * is assumed to be the program name and is ignored.
 *
 * Returns: Options structure filled out with values.
 *
 * Throws: ArgParseError if arguments are invalid.
 */
T parseArgs(T)(
        const(string[]) arguments,
        Config config = Config.default_
        ) pure
    if (is(T == struct))
{
    import std.meta : Alias;
    import std.traits : getUDAs;
    import std.format : format;
    import std.range : chain, enumerate, empty, front, popFront;
    import std.algorithm.iteration : map, filter;

    validateOptions!T;

    T options;

    auto args = splitArgs(arguments);

    // Arguments that have been parsed
    bool[] parsed;
    parsed.length = args.head.length;

    // Parsing occurs in two passes:
    //
    //  1. Parse all options
    //  2. Parse all positional arguments
    //
    // After the first pass, only positional arguments and invalid options will
    // be left.

    for (size_t i = 0; i < args.head.length; ++i)
    {
        auto opt = splitOption(args.head[i]);

        if (immutable name = optionToName(opt.head))
        {
            foreach (member; __traits(allMembers, T))
            {
                alias symbol = Alias!(__traits(getMember, options, member));
                alias optUDAs = getUDAs!(symbol, Option);

                static if (optUDAs.length > 0)
                {
                    if (optUDAs[0] == name)
                    {
                        parsed[i] = true;

                        static if (hasArgument!(typeof(symbol)))
                        {
                            if (opt.tail)
                            {
                                static if (isArgumentHandler!(typeof(symbol)))
                                    __traits(getMember, options, member)(opt.tail);
                                else
                                    __traits(getMember, options, member) =
                                        parseArg!(typeof(symbol))(opt.tail);
                            }
                            else
                            {
                                ++i;

                                if (i >= args.head.length || isOption(args.head[i]))
                                    throw new ArgParseError(
                                            "Expected argument for option '%s'"
                                            .format(opt.head)
                                            );

                                static if (isArgumentHandler!(typeof(symbol)))
                                    __traits(getMember, options, member)(args.head[i]);
                                else
                                    __traits(getMember, options, member) =
                                        parseArg!(typeof(symbol))(args.head[i]);

                                parsed[i] = true;
                            }
                        }
                        else
                        {
                            if (opt.tail)
                                throw new ArgParseError(
                                        "Option '%s' does not take an argument"
                                        .format(opt.head)
                                        );

                            // Handle a request for help
                            if ((config & Config.handleHelp) ==
                                    Config.handleHelp && optUDAs[0] == "help")
                                throw new ArgParseHelp("");

                            static if (isOptionHandler!(typeof(symbol)))
                                __traits(getMember, options, member)();
                            else static if (is(typeof(symbol) : OptionFlag))
                                __traits(getMember, options, member) =
                                    OptionFlag.yes;
                            else
                                static assert(false);
                        }
                    }
                }
            }
        }
    }

    if ((config & Config.ignoreUnknown) != Config.ignoreUnknown)
    {
        // Any left over options are erroneous
        for (size_t i = 0; i < args.head.length; ++i)
        {
            if (!parsed[i] && isOption(args.head[i]))
            {
                throw new ArgParseError(
                    "Unknown option '"~ args.head[i] ~"'"
                    );
            }
        }
    }

    // Left over arguments
    auto leftOver = args.head
        .enumerate
        .filter!(a => !parsed[a[0]])
        .map!(a => a[1])
        .chain(args.tail);

    // Only positional arguments are left
    foreach (member; __traits(allMembers, T))
    {
        alias symbol = Alias!(__traits(getMember, options, member));
        alias argUDAs = getUDAs!(symbol, Argument);

        static if (argUDAs.length > 0)
        {
            // Keep consuming arguments until the multiplicity is satisfied
            for (size_t i = 0; i < argUDAs[0].upperBound; ++i)
            {
                // Out of arguments?
                if (leftOver.empty)
                {
                    if (i >= argUDAs[0].lowerBound)
                        break; // Multiplicity is satisfied

                    throw new ArgParseError(argUDAs[0].multiplicityError(i));
                }

                // Set argument or add to list of arguments.
                static if (argUDAs[0].upperBound <= 1)
                {
                    static if (isArgumentHandler!(typeof(symbol)))
                        __traits(getMember, options, member)(leftOver.front);
                    else
                        __traits(getMember, options, member) =
                            parseArg!(typeof(symbol))(leftOver.front);
                }
                else
                {
                    static if (isArgumentHandler!(typeof(symbol)))
                        __traits(getMember, options, member)(leftOver.front);
                    else
                    {
                        import std.range.primitives : ElementType;
                        __traits(getMember, options, member) ~=
                            parseArg!(ElementType!(typeof(symbol)))(leftOver.front);
                    }
                }

                leftOver.popFront();
            }
        }
    }

    if (!leftOver.empty)
        throw new ArgParseError("Too many arguments specified");

    return options;
}

///
unittest
{
    static struct Options
    {
        string testValue;

        @Option("test")
        void test(string arg) pure
        {
            testValue = arg;
        }

        @Option("help")
        @Help("Prints help on command line arguments.")
        OptionFlag help;

        @Option("version")
        @Help("Prints version information.")
        OptionFlag version_;

        @Argument("path", Multiplicity.oneOrMore)
        @Help("Path to the build description.")
        string[] path;

        @Option("dryrun", "n")
        @Help("Don't make any functional changes. Just print what might" ~
              " happen.")
        OptionFlag dryRun;

        @Option("threads", "j")
        @Help("The number of threads to use. Default is the number of" ~
              " logical cores.")
        size_t threads;

        @Option("color")
        @Help("When to colorize the output.")
        @MetaVar("{auto,always,never}")
        string color = "auto";
    }

    immutable options = parseArgs!Options([
            "arg1",
            "--version",
            "--test",
            "test test",
            "--dryrun",
            "--threads",
            "42",
            "--color=test",
            "--",
            "arg2",
        ]);

    assert(options == Options(
            "test test",
            OptionFlag.no,
            OptionFlag.yes,
            ["arg1", "arg2"],
            OptionFlag.yes,
            42,
            "test",
            ));
}

///
unittest
{
    static struct Options
    {
        @Option("help")
        @Help("Prints help on command line usage.")
        OptionFlag help;

        @Option("version")
        @Help("Prints version information.")
        OptionFlag version_;

        @Argument("command", Multiplicity.optional)
        @Help("Subcommand")
        string command;

        @Argument("args", Multiplicity.zeroOrMore)
        @Help("Arguments for the command.")
        const(string)[] args;
    }

    immutable options = parseArgs!Options([
            "--version",
            "status",
            "--asdf",
            "blah blah"
        ], Config.ignoreUnknown);

    assert(options == Options(
            OptionFlag.no,
            OptionFlag.yes,
            "status",
            ["--asdf", "blah blah"]
            ));
}
