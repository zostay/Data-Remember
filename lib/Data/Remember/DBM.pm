use strict;
use warnings;

package Data::Remember::DBM;
use base qw/ Data::Remember::Memory /;

use Carp;
use DBM::Deep;

=head1 NAME

Data::Remember::DBM - a long-term memory brain plugin for Data::Remember

=head1 SYNOPSIS

  use Data::Remember DBM => file => 'brain.db';

  remember something => 'what?';

=head1 DESCRIPTION

This is a brain plugin module for L<Data::Memory> that persists everything stored using L<DBM::Deep>. To use this module you must specify the "file" argument to tell the module where to store the files.

=head1 METHODS

=head2 new file => FILENAME

Pass the name of the file to use to store the persistent data in. The "file" argument is required.

=cut

sub new {
    my $class = shift;
    my %args  = @_;

    croak 'You must specify a "file" to store the data in.'
        unless $args{file};

    bless { brain => DBM::Deep->new( $args{file} ) }, $class;
}

=head2 dbm

If you need to do any locking or additional work with L<DBM::Deep> directly, use this method to get a reference to the current instance.

  my $dbm = brain->dbm;

=cut

sub dbm {
    my $self = shift;
    return $self->{brain};
}

=head1 SEE ALSO

L<Data::Remember>, L<Data::Remember::Memory>

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
