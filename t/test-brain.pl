use strict;
use warnings;

plan tests => 18;

can_ok('main', 'remember');
can_ok('main', 'recall');
can_ok('main', 'forget');

remember foo => 1;
remember bar => 2;
remember baz => 3;

remember_these qux => 4;
remember_these qux => 5;
remember_these qux => 6;

is(recall 'foo', 1, 'recalled foo is 1');
is(recall 'bar', 2, 'recalled bar is 2');
is(recall 'baz', 3, 'recalled baz is 3');
is_deeply([@{recall('qux')}], [ 4, 5, 6 ], 'recalled qux is [ 4, 5, 6 ]');

my $bar = recall_and_update { $_++ } 'bar';
is($bar, 2, 'recall_and_update returned 2');
is(recall 'bar', 3, 'recall_and_update changed bar to 3');

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

is(recall [ foo => 1, bar => 2, baz => 3, 'fantastic' ], 10, 'fantastic => 10');
is(recall [ foo => 1, bar => 2, baz => 3, 'supreme' ], 9, 'supreme => 9');
is(recall [ foo => 1, bar => 2, baz => 3, 'excellent' ], 8, 'excellent => 8');
