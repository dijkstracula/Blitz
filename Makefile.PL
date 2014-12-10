use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::Blitz',
    AUTHOR              => 'Nathan Taylor <nbtaylor@gmail.com>',
    VERSION_FROM        => 'lib/App/Blitz.pm',
    ABSTRACT_FROM       => 'lib/App/Blitz.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Blitz-*' },
);
