event_src = [
    'timer/Kqueue.d',
    'timer/Epoll.d',
    'timer/Common.d',
    'timer/package.d',
    'timer/IOCP.d',
    'selector/Kqueue.d',
    'selector/Epoll.d',
    'selector/package.d',
    'selector/Selector.d',
    'selector/IOCP.d',
    'EventLoopGroup.d',
    'package.d',
    'EventLoop.d',
]

event_lib = library('hunt-event',
    event_src,
    install: true,
    version: meson.project_version(),
    soversion: project_soversion,
    dependencies: [common_dep],
    d_module_versions: d_mod_version,
)

pkgc.generate(event_lib,
              name: 'hunt-event',
              subdirs: 'd/hunt/hunt/event',
              version: meson.project_version(),
              description: 'Hunt event library.',
              d_module_versions: d_mod_version,
)
