use Module::Build;
my $build = new Module::Build(
    module_name => 'SeqMiner',
	dist_author => 'Diego Diez <diez@kuicr.kyoto-u.ac.jp',
    dist_version_from => 'lib/SeqMiner.pm',
	install_base => $ENV{HOME},
);

$build->create_build_script;
