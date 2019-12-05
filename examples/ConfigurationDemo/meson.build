app_config_dir = join_paths(hunt_doc_dir, 'examples', 'ConfigurationDemo')

conf = configuration_data()

conf.set('CONF_PREFIX', app_config_dir)

app_src = configure_file(
    input: 'source/app.d',
    output: 'app.d',
    configuration: conf,
)

executable(
    'hunt-config-demo',
    ['source/settings.d', app_src],
    dependencies: hunt_dep,
    d_module_versions: d_mod_version,
    d_debug: d_debug,
    include_directories: include_directories('source'),
    install: true,
    link_args: '-link-defaultlib-shared',
)

install_data(
    ['application.conf', 'test.config', 'test2.config'],
    install_dir: app_config_dir,
)
