performance_test_src = [
    'source/app.d',
]

performance_test = executable('hunt-performance-test',
    performance_test_src,
    dependencies: hunt_dep,
    d_module_versions: d_mod_version,
    d_debug: d_debug,
    include_directories: include_directories('source'),
    link_args: link_runtime_shared_arg,
)

#Disable for now; gets stuck
#test('performance-test', performance_test)
