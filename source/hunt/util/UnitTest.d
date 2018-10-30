module hunt.util.UnitTest;

void testUnits(T)()
{
	enum v = generateUnitTests!T;
	// pragma(msg, v);
	mixin(v);
}

string generateUnitTests(T)()
{
	import std.string;
	import std.algorithm;
    import std.traits;
    
    enum fullTypeName = fullyQualifiedName!(T);
    enum memberModuleName = moduleName!(T);

	string str;
    str ~= `import std.stdio;
writeln("=================================");
writeln("testing ` ~ fullTypeName ~ `     ");
writeln("=================================");

`;
    str ~= "import " ~ memberModuleName ~ ";\n";
	str ~= "auto t = new "~ T.stringof ~ "();\n";

	foreach (memberName; __traits(derivedMembers, T))
	{
		// enum currentMember = __traits(getMember, T, memberName);
		static if(memberName.startsWith("test") || memberName.endsWith("Test") || 
			hasUDA!(__traits(getMember, T, memberName), Test))
		{
			alias memberType = typeof(__traits(getMember, T, memberName));
			static if(is(memberType == function))
			{
				str ~= `writeln("\n========> running: ` ~ memberName ~ "\");\n";
				str ~= "t." ~ memberName ~ "();\n";
			}
		} 
	}
	return str;
}


/**
*/
struct Test {
	
}