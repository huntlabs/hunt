executable('hunt-udp-client-demo',
    'source/client.d',
    dependencies: hunt_dep,
    d_debug: d_debug,
    d_module_versions: d_mod_version,
    include_directories: include_directories('source'),
    install: true,
    link_args: link_runtime_shared_arg,
)

executable('hunt-udp-server-demo',
    'source/server.d',
    dependencies: hunt_dep,
    d_debug: d_debug,
    d_module_versions: d_mod_version,
    include_directories: include_directories('source'),
    install: true,
    link_args: link_runtime_shared_arg,
)
