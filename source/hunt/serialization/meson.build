serialization_src = [
    'BinarySerializer.d',
    'Common.d',
    'JsonSerializer.d',
    'package.d',
]

serialization_lib = library('hunt-serialization',
    serialization_src,
    install: true,
    version: meson.project_version(),
    soversion: project_soversion,
    dependencies: [common_dep],
    d_module_versions: d_mod_version,
)

pkgc.generate(serialization_lib,
              name: 'hunt-serialization',
              subdirs: 'd/hunt/hunt/serialization',
              version: meson.project_version(),
              description: 'Hunt serialization library.',
              d_module_versions: d_mod_version,
)
