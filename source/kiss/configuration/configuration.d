module model.configuration.configuration;

import std.conv;
import std.exception;
import std.array;
import std.stdio;
import std.string;
import std.experimental.logger;
import kiss.configuration;

class ConfigurationValue : BaseConfigValue
{
    override @property BaseConfigValue value(string name){
        auto v =  _map.get(name, null);
        enforce!NoValueHasException(v,format(" %s is not in config! ",name));
        return v;
    }

    override @property string value(){
        return _value;
    }

    auto opDispatch(string s)()
    {
        return cast(ConfigurationValue)(value(s));
    }
    
private :
    string _value;
    ConfigurationValue[string] _map;
}

class Configuration : BaseConfig
{	
	this(string filename, string section = "")
	{
		_section = section;
		loadConfig(filename);
	}
	
	override BaseConfigValue value(string name){
		return _value.value(name);
	}
	
	override @property BaseConfigValue topValue(){
		return _value;
	}
	auto opDispatch(string s)()
	{
		return _value.opDispatch!(s)();
	}
	
private:
	void loadConfig(string filename)
	{
		_value = new ConfigurationValue();

		import std.file;
		if(!exists(filename))return;
		import std.format;
		auto f = File(filename,"r");
		if(!f.isOpen()) return;
		scope(exit) f.close();
		string section = "";
		int line = 1;
		while(!f.eof())
		{
			scope(exit) line += 1;
			string str = f.readln();
			str = strip(str);
			if(str.length == 0) continue;
			if(str[0] == '#' || str[0] == ';') continue;
			auto len = str.length -1;
			if(str[0] == '[' && str[len] == ']')
			{
				section = str[1..len].strip;
				continue;
			}
			if(section != _section && section != "")
				continue;// 不是自己要读取的分段，就跳过
			auto site = str.indexOf("=");
			enforce!ConfFormatException((site > 0),format("the format is erro in file %s, in line %d",filename,line));
			string key = str[0..site].strip;
			setValue(split(key,'.'),str[site + 1..$].strip);
		}
	}
	
	void setValue(string[] list, string value)
	{
		auto cvalue = _value;
		foreach(ref str ; list){
			if(str.length == 0) continue;
			auto tvalue = cvalue._map.get(str,null);
			if(tvalue is null){ // 不存在就追加一个
				tvalue = new ConfigurationValue();
				cvalue._map[str] = tvalue;
			}
			cvalue = tvalue;
		}
		if(cvalue is _value)
			return;
		cvalue._value = value;
	}
	
private:
	string _section;
	ConfigurationValue _value;
}

version(unittest){
	import kiss.configuration.read;

	@ConfigItem("app")
	class TestConfig
	{
		@ConfigItem()
		string test;
		@ConfigItem()
		double time;

		@ConfigItem("http")
		TestHttpConfig listen;

		@ConfigItem("optial",true)
		int optial = 500;

		@ConfigItem(true)
		int optial2 = 500;

		mixin ReadConfig!TestConfig;
	}

	@ConfigItem("HTTP")
	struct TestHttpConfig
	{
		@ConfigItem("listen")
		int value;

		mixin ReadConfig!TestHttpConfig;
	}


}


unittest
{
	import std.stdio;
	import FE = std.file;
	FE.write("test.config","app.http.listen = 100 \nhttp.listen = 100 \napp.test = \napp.time = 0.25 \n# this is  \n ; start dev\n [dev]\napp.test = dev");
	auto conf = new Configuration("test.config");
	assert(conf.http.listen.value.as!long() == 100);
	assert(conf.app.test.value() == "");
	
	auto confdev = new Configuration("test.config","dev");
	long tv = confdev.http.listen.value.as!long;
	assert(tv == 100);
	assert(confdev.http.listen.value.as!long() == 100);
	writeln("----------" ,confdev.app.test.value());
	string tvstr = cast(string)confdev.app.test.value;
    
	assert(tvstr == "dev");
	assert(confdev.app.test.value() == "dev");
	bool tvBool = confdev.app.test.value.as!bool;
	assert(tvBool);

	string str;
	auto e = collectException!NoValueHasException(confdev.app.host.value(), str);
	assert(e && e.msg == " host is not in config! ");

	TestConfig test = TestConfig.readConfig(confdev);
	assert(test.test == "dev");
	assert(test.time == 0.25);
	assert(test.listen.value == 100);
	assert(test.optial == 500);
	assert(test.optial2 == 500);
}
