project(
  'hunt', 'd',
  version: '1.5.0',
  license: 'Apache-2.0',
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

subdir('source')

subdir('examples')

#subdir('docs')

#subdir('resources')
