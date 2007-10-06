use strict;
use warnings;

use Test::More tests => 50;

use Data::Remember POE => 'Memory';
use POE;

sub ping {
    my $kernel = $_[KERNEL];

    my $pings = recall 'pings';
    remember pings => $pings - 1;

    $kernel->yield( 'ping' ) if $pings > 1;
    $kernel->yield( 'pong' );
}

sub pong {
    pass('ponged again');
}

sub _start {
    my $kernel = $_[KERNEL];

    remember pings => 5;

    $kernel->yield( 'ping' );
}

for ( 1 .. 10 ) {
    POE::Session->create(
        inline_states => {
            _start => \&_start,
            ping   => \&ping,
            pong   => \&pong,
        },
        heap => brain->new_heap,
    );
}

POE::Kernel->run;
