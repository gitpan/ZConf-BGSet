use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ZConf::BGSet',
    AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/ZConf/BGSet.pm',
    ABSTRACT_FROM       => 'lib/ZConf/BGSet.pm',
    INST_SCRIPT => 'bin',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ZConf-BGSet-*' },
);
