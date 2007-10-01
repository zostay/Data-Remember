use strict;
use warnings;

package Data::Remember::Memory;

our $VERSION = '0.000001';

=head1 NAME

Data::Remember::Memory - a short-term memory brain plugin for Data::Remember

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

    my $object = $self->{brain};
    for my $que_entry (@$que) {
        if (defined $object->{$que_entry}) {
            $object = $object->{$que_entry};
        }
        else {
            $object = $object->{$que_entry} = {};
        }
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

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
