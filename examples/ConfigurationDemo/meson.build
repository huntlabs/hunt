conf_demo_src = [
    'source/app.d',
    'source/settings.d',
]

executable('hunt-config-demo',
    conf_demo_src,
    dependencies: hunt_dep,
    d_module_versions: d_mod_version,
    include_directories: include_directories('source'),
    install: true,
)
