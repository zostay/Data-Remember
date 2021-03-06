use strict;
use warnings;

package Data::Remember::Memory;
# ABSTRACT: a short-term memory brain plugin for Data::Remember

use Scalar::Util qw/ reftype /;

=head1 SYNOPSIS

  use Data::Remember 'Memory';

  remember something => 'what?';

=head1 DESCRIPTION

This is a very simple brain for L<Data::Remember> that just stores everything in Perl data structures in memory.

=head1 METHODS

=head2 new

Takes no arguments or special parameters. Any parameters will be ignored.

=cut

sub new {
    my $class = shift;
    bless { brain => {} }, $class;
}

=head2 remember QUE, FACT

Stores the given FACT in a Perl data structure under QUE.

=cut

sub remember {
    my $self = shift;
    my $que  = shift;
    my $fact = shift;

    my $last_que = pop @$que;
    my $que_remaining = scalar @$que;

    my $object = $self->{brain};
    for my $que_entry (@$que) {
        if (defined $object->{$que_entry}) {

            if ($que_remaining == 0 
                    or (ref $object->{$que_entry} 
                        and reftype $object->{$que_entry} eq 'HASH')) {
                $object = $object->{$que_entry};
            }
            
            # overwrite previous non-hash fact with something more agreeable
            else {
                $object = $object->{$que_entry} = {}
            }
        }

        else {
            $object = $object->{$que_entry} = {};
        }

        $que_remaining--;
    }

    $object->{$last_que} = $fact;
}

=head2 recall QUE

Recalls the fact stored at QUE.

=cut

sub recall {
    my $self = shift;
    my $que  = shift;

    my $object = $self->{brain};
    for my $que_entry (@$que) {
        return unless ref $object and reftype $object eq 'HASH';

        if (defined $object->{$que_entry}) {
            $object = $object->{$que_entry};
        }

        else {
            return;
        }
    }

    return scalar $object;
}

=head2 forget QUE

Forgets the fact stored at QUE.

=cut

sub forget {
    my $self = shift;
    my $que  = shift;

    my $last_que = pop @$que;

    my $object = $self->{brain};
    for my $que_entry (@$que) {
        if (defined $object->{$que_entry}) {
            $object = $object->{$que_entry};
        }
        else {
            return;
        }
    }

    delete $object->{$last_que};
}

=head1 SEE ALSO

L<Data::Remember>

=cut

1;
