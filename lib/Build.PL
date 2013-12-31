use Module::Build;

my $build = Module::Build->new (
    module_name => 'Calendar',
    license => 'perl',
);

$build->create_build_script;
