[![Build Status](https://travis-ci.org/huntlabs/hunt.svg?branch=master)](https://travis-ci.org/huntlabs/hunt)

# Hunt library
A refined core library for D programming language.

## Modules
 * hunt.io ( TcpListener / TcpStream )
 * hunt.container (Java alike)
 * hunt.event ( kqueue / epoll / iocp )
 * hunt.lang
 * hunt.logging
 * hunt.math (BigIngeger etc.)
 * hunt.string
 * hunt.util (buffer configration memory radix-tree serialize timer etc.)
 * hunt.time (Compatible with Java java.time API design)

## Platforms
 * FreeBSD
 * Windows
 * OSX
 * Linux

## Libraries
 * [hunt-net](https://github.com/huntlabs/hunt-net) – An asynchronous event-driven network library written in D.

## Frameworks
 * [hunt-framework](https://github.com/huntlabs/hunt-framework) – Hunt is a high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.

## Benchmarks
![Benchmark](docs/images/benchmark.png)

For details, see [here](docs/benchmark.md).

## Thanks
 * @shove70
 * @n8sh
 * @deviator
 * @jasonwhite
 * @Kripth

## TODO
- [ ] Improve performance
- [ ] Stablize APIs
- [ ] More friendly APIs
- [ ] More examples
- [ ] More common utils
- [ ] Add concurrent modules
