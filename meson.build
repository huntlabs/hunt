project(
  'hunt', 'd',
  version: '1.5.0',
  license: 'Apache-2.0',
)

project_soversion = 0

d_mod_version = ['HAVE_EPOLL']

if get_option('buildtype').startswith('debug')
    d_mod_version += ['HUNT_DEBUG', 'HUNT_IO_DEBUG', 'HUNT_IO_DEBUG_MORE', 'HUNT_CONFIG_DEBUG']
endif

inc_prefix = join_paths(get_option('prefix'), get_option('includedir'), 'd', 'hunt')

subdir('source')

#subdir('examples')

#subdir('docs')

#subdir('resources')
