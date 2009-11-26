use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Trimet::TransitTracker',
    AUTHOR              => 'Brandon Sandrowicz <brandon@sandrowicz.org>',
    VERSION_FROM        => 'lib/WWW/Trimet/TransitTracker.pm',
    ABSTRACT_FROM       => 'lib/WWW/Trimet/TransitTracker.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Trimet-TransitTracker-*' },
);
