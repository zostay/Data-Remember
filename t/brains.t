#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 13 * 4;
use Data::Remember 'Memory';

use YAML::Syck;

YAML::Syck::DumpFile('t/test.yml', {});

our @brains = (
    [ 'Memory' ],
    [ DBM => file => 't/test.db' ],
    [ YAML => file => 't/test.yml' ],
    [ Hybrid => [] => 'Memory', [ foo => 1 ] => [ YAML => file => 't/test.yml' ] ],
);

our $brain;
local $brain;
for $brain (@brains) {
    eval "use Data::Remember \@\$brain";
    die $@ if $@;

    can_ok('main', 'remember');
    can_ok('main', 'recall');
    can_ok('main', 'forget');

    remember foo => 1;
    remember bar => 2;
    remember baz => 3;

    is(recall 'foo', 1, 'recalled foo is 1');
    is(recall 'bar', 2, 'recalled bar is 2');
    is(recall 'baz', 3, 'recalled baz is 3');

    forget 'bar';
    forget 'bar'; # forgetting something twice is redundant, but ok

    is(recall 'foo', 1, 'recalled foo is 1');
    is(recall 'bar', undef, 'recalled bar is forgotten');
    is(recall 'baz', 3, 'recalled baz is 3');

    forget 'foo';

    remember [ foo => 1, bar => 2, baz => 3 ], 'fantastic';
    remember [ foo => 3, bar => 2, baz => 4 ], 'supreme';
    remember [ foo => 1, bar => 3, baz => 2 ], 'excellent';

    is(recall [ foo => 1, bar => 2, baz => 3 ], 'fantastic', 'long key 1 => fantastic');
    is(recall [ foo => 3, bar => 2, baz => 4 ], 'supreme', 'long key 2 => supreme');
    is(recall [ foo => 1, bar => 3, baz => 2 ], 'excellent', 'long key 3 => excellent');

    remember [ foo => 1, bar => 2, baz => 3 ], {
        fantastic => 10,
        supreme   => 9,
        excellent => 8,
    };

    is_deeply(recall [ foo => 1, bar => 2, baz => 3 ], {
        fantastic => 10,
        supreme   => 9,
        excellent => 8,
    }, 'long key 1 => long value');
}

# clean up
unlink 't/test.db';
unlink 't/test.yml';
