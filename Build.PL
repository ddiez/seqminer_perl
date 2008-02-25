use Module::Build;
my $build = new Module::Build(
    module_name => 'varDB',
    dist_version_from => 'lib/varDB.pm',
);

$build->create_build_script;
