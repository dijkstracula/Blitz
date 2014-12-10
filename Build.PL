use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::Blitz',
    license             => 'artistic2',
    dist_author         => 'Nathan Taylor <nbtaylor@gmail.com>',
    dist_version_from   => 'lib/App/Blitz.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
	'WWW::Dict::Leo::Org' => 0
    },
    add_to_cleanup      => [ 'App-Blitz-*' ],
);

$builder->create_build_script();
