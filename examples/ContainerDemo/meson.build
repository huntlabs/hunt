container_demo_src = [
    'source/app.d',
    'source/ArrayListDemo.d',
    'source/BufferUtilsDemo.d',
    'source/common.d',
    'source/HashMapDemo.d',
    'source/HashSetDemo.d',
    'source/LinkedHashMapDemo.d',
    'source/LinkedHashSetDemo.d',
    'source/LinkedListDemo.d',
    'source/MultiMapDemo.d',
    'source/SetDemo.d',
    'source/TreeMapDemo.d',
    'source/TrieTest.d',
]

executable('hunt-container-demo',
    container_demo_src,
    dependencies: hunt_dep,
    d_module_versions: d_mod_version,
    include_directories: include_directories('source'),
    install: true,
    link_args: '-link-defaultlib-shared',
)
