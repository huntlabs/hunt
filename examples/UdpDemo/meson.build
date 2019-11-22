executable('hunt-udp-client-demo',
    'source/client.d',
    dependencies: hunt_dep,
    d_module_versions: d_mod_version,
    include_directories: include_directories('source'),
    install: true,
    link_args: '-link-defaultlib-shared',
)

executable('hunt-udp-server-demo',
    'source/server.d',
    dependencies: hunt_dep,
    d_module_versions: d_mod_version,
    include_directories: include_directories('source'),
    install: true,
    link_args: '-link-defaultlib-shared',
)
