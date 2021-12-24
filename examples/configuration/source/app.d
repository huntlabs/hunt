import std.array;
import std.conv;
import std.stdio;
import std.file;
import std.exception;
import std.path;

import hunt.util.Configuration;
import hunt.logging;

import settings;

import core.time;

void main() {
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

	testArrayConfig();

}

// Allow loading the configuration from some prefix in case we're
// installed somewhere and not run in the repo.
string convertConfigPathToRelative(string configName) {
	mixin("string confPrefix = \"@CONF_PREFIX@\";");
	// We don't want meson to replace the CONF_PREFIX here too,
	// otherwise this would always be true.
	if (confPrefix == join(["@CONF", "_PREFIX@"])) {
		return configName;
	} else {
		auto relConfPath = relativePath(confPrefix, std.file.getcwd);
		return buildPath(relConfPath,  configName);
	}
}

void testApplicationConfig() {
	ConfigBuilder manager;

	manager = new ConfigBuilder(convertConfigPathToRelative("application.conf"));

	// writeln("x======", manager.hunt.application.name);
// FIXME: Needing refactor or cleanup -@zxp at 1/9/2019, 6:37:48 PM
//
	// assert(manager.hunt.application.name == "MYSITE");
	assert(manager.hunt.application.encoding.value() == "UTF-8");
	assert(manager.hunt.application.encoding.value() == "UTF-8");
	assert(manager.hunt.log.path.value().empty);
	assert(manager.hunt.mail.smtp.password.value().empty);

	AppConfig config = manager.build!(AppConfig)();
	assert(config.view.path == "./views/", config.view.path);
}

void testConfig1() {
	ConfigBuilder conf = new ConfigBuilder(convertConfigPathToRelative("test.config"));

	assert(conf.app.node1.node2.node3.node4 is null);

	// assertThrown!(EmptyValueException)(conf.app.node1.node2.node3.node4.value());

	// assert(conf.app.subItem("package").name.value() == "Hunt package"); // use keyword as a node name
	// assert(conf["app"]["package"]["name"].value() == "Hunt package"); // use keyword as a node name

	assert(conf.app.node1.node2.node3.value() == "nothing");
	assert(conf.http.listen.value.as!long() == 100);
	assert(conf.app.buildMode.value() == "default");
	assert(conf.app.time.value() == "0.25");
	assert(conf.app.time.as() == "0.25");
	assert(conf.app.time.as!float() == 0.25);
	string buildMode = conf.app.buildMode.value();
	assert(buildMode == "default");

	assert(conf.getProperty("name") == "GlobleConfiguration");
	assert(conf.getProperty("name___x", "default") == "default");
	assert(conf.getProperty("name___x").empty());
	assert(conf.getProperty("app.buildMode") == "default");

}

void testConfig2() {
	auto conf = new ConfigBuilder(convertConfigPathToRelative("test.config"), "dev");
	assert(conf.http.listen.value.as!long() == 100);
	assert(conf.http.listen.as!long() == 100);
	string buildMode = conf.app.buildMode.value();
	assert(buildMode == "dev");
	assert(conf.getProperty("app.buildMode") == "dev");
}

void testConfigBuilder1() {
	ConfigBuilder manager = new ConfigBuilder(convertConfigPathToRelative("test.config"));

	BuilderTest1Config config = manager.build!BuilderTest1Config();
	assert(config.timeout.total!("msecs") == 234, config.timeout.toString());

	writeln(manager.app.server1.ip.value());
	writeln(manager.app.server1.port.value());
	writeln("..................");
	writeln(config.server1.ip);
	writeln(config.server1.port);

	assert(config.name == "GlobleConfiguration", config.name);
	assert(config.time == 2018, to!string(config.time));

	assert(config.interval1 == 500, to!string(config.interval1));
	assert(config.interval2 == 600, to!string(config.interval2));
	assert(config.interval3 == 700, to!string(config.interval3));

	assert(config.server1.ip == "8.8.6.1", config.server2.ip);
	assert(config.server1.port == 81, to!string(config.server2.port));

	assert(config.server2.ip == "127.0.0.1", config.server2.ip);
	assert(config.server2.port == 8080, to!string(config.server2.port));
}

void testConfigBuilder2() {
	ConfigBuilder manager = new ConfigBuilder(convertConfigPathToRelative("test.config"));

	TestConfig config = manager.build!(TestConfig, "app")();

	// assert(config.package1 !is null);
	// assert(config.package1.name == "Hunt package", config.package1.name);
	// assert(config.package2 !is null);
	// assert(config.package2.name == "Hunt pkg", config.package2.name);

	assert(config.name == "Hunt-dev", config.name);
	assert(config.time == 0.25, to!string(config.time));

	assert(config.interval1 == 550, to!string(config.time));
	assert(config.interval2 == 550, to!string(config.time));
	assert(config.interval3 == 888, to!string(config.time));

	assert(config.server1.ip == "8.8.7.1", config.server1.ip);
	assert(config.server1.port == 8071, to!string(config.server1.port));

	assert(config.server2.ip == "8.8.10.1", config.server2.ip);
	assert(config.server2.port == 8081, to!string(config.server2.port));

	assert(config.description == "Shanghai Puto Inc.", config.description);
}

void testConfigBuilder3() {
	ConfigBuilder manager = new ConfigBuilder(convertConfigPathToRelative("test.config"));

	TestConfigEx config = manager.build!(TestConfigEx, "app")();

	writeln(config.fullName);
	writeln(config.name);
	writeln(config.time);
}


void testArrayConfig() {

	writeln("\n\n===== testing Array Config =====\n");
	ConfigBuilder manager = new ConfigBuilder(convertConfigPathToRelative("test2.config"));

	assert(manager["name"].value() == "Test ArrayConfig");
	assert(manager["servers[0]"]["port"].value() == "81");
	assert(manager["ages"].value() == "20, 30, 40");
	assert(manager["users"].value() == "user01, user02, user03");

	//
	ArrayTestConfig config = manager.build!(ArrayTestConfig)();

	assert(config.name == "Test ArrayConfig");
	assert(config.ages == [20, 30, 40]);
	assert(config.users == ["user01", "user02", "user03"]);

	ServerSettings[] servers = config.servers;
	assert(servers.length == 2);
	assert(servers[0].ip == "8.8.6.1");
	assert(servers[1].port == 82);
}
