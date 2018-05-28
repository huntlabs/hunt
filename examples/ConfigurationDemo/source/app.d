
import std.array;
import std.stdio;
import std.file;
import std.exception;

import kiss.util.configuration;

void main()
{
	writeln("===== testing application.conf =====\n");
	testApplicationConfig();
	
	writeln("\n\n===== testing test.config =====\n");
	testConfig1();

	writeln("\n\n===== testing test.config =====\n");
	testConfig2();
}

void testApplicationConfig()
{
	Configuration config = new Configuration("application.conf");

	assert(config.application.encoding.value() == "UTF-8");
	assert(config.log.path.value().empty);
	assert(config.mail.smtp.password.value().empty);

}

void testConfig1()
{
	auto conf = new Configuration("test.config");

	assertThrown!(EmptyValueException)(conf.app.node1.node2.node3.node4.value());
    assert(conf.app.node1.node2.node3.value() == "nothing");
    assert(conf.http.listen.value.as!long() == 100);
    assert(conf.app.buildMode.value() == "default");
    assert(conf.app.time.value() == "0.25");
    assert(conf.app.time.as() == "0.25");
    assert(conf.app.time.as!float() == 0.25);
    string buildMode = conf.app.buildMode.value();
    assert(buildMode == "default");
}

void testConfig2()
{
	auto conf = new Configuration("test.config", "dev");
    assert(conf.http.listen.value.as!long() == 100);
    assert(conf.http.listen.as!long() == 100);
    string buildMode = conf.app.buildMode.value();
    assert(buildMode == "dev");
}