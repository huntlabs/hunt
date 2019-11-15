math_src = [
    'BigDecimal.d',
    'BigInteger.d',
    'MutableBigInteger.d',
    'package.d',
]

math_lib = library('hunt-math',
    math_src,
    install: true,
    version: meson.project_version(),
    soversion: project_soversion,
    dependencies: [common_dep],
    d_module_versions: d_mod_version,
)

pkgc.generate(math_lib,
              name: 'hunt-math',
              subdirs: 'd/hunt-math',
              version: meson.project_version(),
              description: 'Hunt math library.',
              d_module_versions: d_mod_version,
)
