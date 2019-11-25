project(
  'hunt', 'd',
  version: '1.5.0',
  license: 'Apache-2.0',
  # https://github.com/mesonbuild/meson/issues/3337
  meson_version: '>=0.46',
)

project_soversion = 0

d_mod_version = [ ]

if get_option('buildtype').startswith('debug')
    d_mod_version += ['HUNT_DEBUG', 'HUNT_DEBUG_MORE', 'HUNT_CONCURRENCY_DEBUG']
endif

target_os = host_machine.system()

if target_os  == 'linux'
    d_mod_version += ['HAVE_EPOLL']
elif target_os == 'windows'
    d_mod_version += ['HAVE_IOCP']
else
    d_mod_version += ['HAVE_KQUEUE']
endif

inc_prefix = join_paths(get_option('prefix'), get_option('includedir'), 'd', 'hunt')

src_inc = include_directories('source')

hunt_doc_dir = join_paths(get_option('prefix'), get_option('datadir'), 'doc', 'hunt')

hunt_data_dir = join_paths(get_option('prefix'), get_option('datadir'), 'hunt')

subdir('source')

subdir('examples')

install_subdir('docs',
    install_dir: hunt_doc_dir,
    strip_directory: true,
)

install_subdir('resources', install_dir: hunt_data_dir)

lines = ['',
    'Hunt version:    ' + meson.project_version(),
    'Buildtype:       ' + get_option('buildtype'),
    'D Versions:      ' + ' '.join(d_mod_version),
    'Target OS:       ' + host_machine.system(),
    'Prefix:          ' + get_option('prefix'),
]

indent = '        '
summary = indent + ('\n' + indent).join(lines)
message('Configuration summary:\n@0@\n'.format(summary))

