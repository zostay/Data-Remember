use strict;
use warnings;

use Test::More tests => 5;

use Data::Remember YAML => file => 't/load-test.yml';

is_deeply(recall 'something', { foo => 1, bar => 2, baz => 3, qux => 4 });
is(recall [ something => 'foo' ], 1);
is(recall [ something => 'bar' ], 2);
is(recall [ something => 'baz' ], 3);
is(recall [ something => 'qux' ], 4);
