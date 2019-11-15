logging_src = [
    'ConsoleLogger.d',
    'Helper.d',
    'Logger.d',
    'package.d',
]

logging_lib = library('hunt-logging',
    logging_src,
    install: true,
    version: meson.project_version(),
    soversion: project_soversion,
    dependencies: [common_dep],
    d_module_versions: d_mod_version,
)

pkgc.generate(logging_lib,
              name: 'hunt-logging',
              subdirs: 'd/hunt-logging',
              version: meson.project_version(),
              description: 'Hunt logging library.',
              d_module_versions: d_mod_version,
)
