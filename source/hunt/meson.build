common_src = [
    'Assert.d',
    'Boolean.d',
    'Byte.d',
    'Char.d',
    'Double.d',
    'Enum.d',
    'Exceptions.d',
    'Float.d',
    'Functions.d',
    'Integer.d',
    'Long.d',
    'Nullable.d',
    'Number.d',
    'Object.d',
    'Short.d',
    'String.d',
]

common_lib = library('hunt-common',
    common_src,
    install: true,
    include_directories: include_directories('../'),
    version: meson.project_version(),
    soversion: project_soversion,
    d_module_versions: d_mod_version,
)

common_dep = declare_dependency(
    include_directories: include_directories('../'),
    link_with: common_lib, 
)

pkgc.generate(common_lib, name: 'hunt-common',
              subdirs: 'd/hunt/hunt',
              version: meson.project_version(),
              description: 'Hunt common library.',
              d_module_versions: d_mod_version,
)

subdir('concurrency')
subdir('event')
subdir('io')
subdir('logging')
subdir('math')
subdir('serialization')
subdir('system')
subdir('text')
subdir('util')
subdir('collection')
