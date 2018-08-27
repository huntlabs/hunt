
import std.array;
import std.conv;
import std.stdio;
import std.file;
import std.exception;

import hunt.util.configuration;

import settings;

void main()
{
	writeln("===== testing application.conf =====\n");
	testApplicationConfig();
	
	writeln("\n===== testing test.config =====\n");
	testConfig1();

	writeln("\n===== testing test.config =====\n");
	testConfig2();

	writeln("\n===== testing Configuration Builder 1 =====\n");
	testConfigBuilder1();

	writeln("\n\n===== testing Configuration Builder 2 =====\n");
	testConfigBuilder2();

	writeln("\n\n===== testing Configuration Builder 3 =====\n");
	testConfigBuilder3();
}

void testApplicationConfig()
{
	ConfigBuilder manager = new ConfigBuilder("application.conf");

	assert(manager.hunt.application.name.value() == "MYSITE");
	assert(manager.hunt.application.encoding.value() == "UTF-8");
	assert(manager.hunt.application.encoding.value() == "UTF-8");
	assert(manager.hunt.log.path.value().empty);
	assert(manager.hunt.mail.smtp.password.value().empty);

	AppConfig config = manager.build!(AppConfig)();
	assert(config.view.path == "./views/", config.view.path);
}

void testConfig1()
{
	auto conf = new ConfigBuilder("test.config");

	assertThrown!(EmptyValueException)(conf.app.node1.node2.node3.node4.value());

    assert(conf.app.subItem("package").name.value() == "Kiss package"); // use keyword as a node name
    assert(conf["app"]["package"]["name"].value() == "Kiss package"); // use keyword as a node name
	
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
	auto conf = new ConfigBuilder("test.config", "dev");
    assert(conf.http.listen.value.as!long() == 100);
    assert(conf.http.listen.as!long() == 100);
    string buildMode = conf.app.buildMode.value();
    assert(buildMode == "dev");
}

void testConfigBuilder1()
{
	ConfigBuilder manager = new ConfigBuilder("test.config");

	BuilderTest1Config config = manager.build!BuilderTest1Config();

	writeln(config.name);
	writeln(config.time);
	writeln(config.interval1);
	writeln(config.interval2);
	writeln(config.interval3);
	
	writeln(config.server1.ip);
	writeln(config.server1.port);


	assert(config.name == "GlobleConfiguration", config.name);
	assert(config.time == 2018, to!string(config.time));

	assert(config.interval1 == 500, to!string(config.time));
	assert(config.interval2 == 600, to!string(config.time));
	assert(config.interval3 == 700, to!string(config.time));

	assert(config.server2.ip == "127.0.0.1", config.server2.ip);
	assert(config.server2.port == 8080, to!string(config.server2.port));
}


void testConfigBuilder2()
{
	ConfigBuilder manager = new ConfigBuilder("test.config");

	TestConfig config = manager.build!(TestConfig, "app")();

	assert(config.package1 !is null);
	assert(config.package1.name == "Kiss package", config.package1.name);
	assert(config.package2 !is null);
	assert(config.package2.name == "Kiss pkg", config.package2.name);
	
	assert(config.name == "Kiss-dev", config.name);
	assert(config.time == 0.25, to!string(config.time));

	assert(config.interval1 == 550, to!string(config.time));
	assert(config.interval2 == 550, to!string(config.time));
	assert(config.interval3 == 888, to!string(config.time));

	assert(config.server1.ip == "8.8.7.1", config.server1.ip);
	assert(config.server1.port == 8071, to!string(config.server1.port));

	assert(config.server2.ip == "8.8.10.1", config.server2.ip);
	assert(config.server2.port == 8081, to!string(config.server2.port));

	assert(config.description == "Shanghai Putao Ltd.", config.description);
}



void testConfigBuilder3()
{
	ConfigBuilder manager = new ConfigBuilder("test.config");

	TestConfigEx config = manager.build!(TestConfigEx, "app")();

	writeln(config.fullName);
	writeln(config.name);
	writeln(config.time);
}
