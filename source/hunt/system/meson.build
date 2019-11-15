system_src = [
    'Environment.d',
    'Error.d',
    'Locale.d',
    'Memory.d',
    'package.d',
    'syscall/os/FreeBSD.d',
    'syscall/os/Linux.d',
    'syscall/os/OSX.d',
    'syscall/package.d',
    'TimeZone.d',
    'WindowsHelper.d',
]

system_lib = library('hunt-system',
    system_src,
    install: true,
    version: meson.project_version(),
    soversion: project_soversion,
    dependencies: [common_dep],
    d_module_versions: d_mod_version,
)

pkgc.generate(system_lib,
              name: 'hunt-system',
              subdirs: 'd/hunt/hunt/system',
              version: meson.project_version(),
              description: 'Hunt system library.',
              d_module_versions: d_mod_version,
)
