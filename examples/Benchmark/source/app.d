/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */

import std.getopt;
import std.parallelism;
import std.stdio;

import HttpServer;


void main(string[] args) {
	// globalLogLevel(LogLevel.warning);

	ushort port = 8080;
	GetoptResult o = getopt(args, "port|p", "Port (default 8080)", &port);
	if (o.helpWanted) {
		defaultGetoptPrinter("A simple http server powered by Hunt!", o.options);
		return;
	}

	HttpServer httpServer = new HttpServer("0.0.0.0", port, totalCPUs-1);
	writefln("listening on %s", httpServer.bindingAddress.toString());
	httpServer.start();
}
