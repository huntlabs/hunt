performance_test_src = [
    'source/app.d',
]

performance_test = executable('hunt-performance-test',
    performance_test_src,
    dependencies: hunt_dep,
    d_module_versions: d_mod_version,
    include_directories: include_directories('source'),
)

test('performance-test', performance_test)
