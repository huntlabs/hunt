timer_demo_src = [
    'source/app.d',
]

executable('hunt-timer-demo',
    timer_demo_src,
    dependencies: hunt_dep,
    d_module_versions: d_mod_version,
    d_debug: d_debug,
    include_directories: include_directories('source'),
    install: true,
    link_args: '-link-defaultlib-shared',
)
