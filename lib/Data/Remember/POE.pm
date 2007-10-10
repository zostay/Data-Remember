use strict;
use warnings;

package Data::Remember::POE;

=head1 NAME

Data::Remember::POE  a brain for Data::Remember linked to the session heap

=head1 SYNOPSIS

  # An absurd POE programming demonstrating how Data::Remember::POE works
  
  use Data::Remember POE => 'Memory';
  use POE;

  POE::Session->create(
      inline_states => {
          _start      => \&start,
          count_to_10 => \&count_to_10,
          print_count => \&print_count,
      },
      heap => brain->new_heap,
  );
  POE::Kernel->run;

  sub start {
      my $kernel = $_[KERNEL];
      $kernel->yield( 'count_to_10' );
  }

  sub count_to_10 {
      my $kernel = $_[KERNEL];

      for my $count ( 1 .. 10 ) {
          remember [ count => $count ] = "The count is $count.\n";
          $kernel->yield( print_count => $count );
      }
  }

  sub print_count {
      my ($kernel, $count) = @_[KERNEL,ARG0];

      my $message = recall [ count => $count ];
      print $message;
  }

=head1 DESCRIPTION

Normally, when using L<Data::Remember>, the brain used is linked to the package from which the various functions are called. By using L<Data::Remember::POE> to store your brain, the calls to C<remember>, C<recall>, and C<forget> will instead work according to the current POE session. 

This means that it's possible to define two POE sessions that use L<Data::Remember> from the same package, but each will use a different brain.

=head1 METHODS

=head2 new CONFIG

Creates a new object and tells the brain to use C<CONFIG> as the default heap configuration.

=cut

sub new {
    my $class  = shift;
    my @config = @_;

    return bless { config => \@config }, $class;
}

=head2 new_heap [ CONFIG ]

Creates a new brain object to be stored in a sessions heap established when L<POE::Session/create> is called. This new heap will be created according to the configuration from when L<Data::Remember> was used. For example,

  use Data::Remember POE => 'Memory';

This declaration would case C<new_heap> to initialize a new brain using L<Data::Remember::Memory>.

You may also specify a C<CONFIG> argument, which will override the configuration set when L<Data::Remember> was used. For example,

  POE::Session->create(
      inline_states => { ... },
      heap => brain->new_heap( YAML => file => 'brain.yml' ),
  );

This overrides whatever options were set during the use and uses L<Data::Remember::YAML> instead.

=cut

sub new_heap {
    my $self = shift;

    my @config = scalar(@_) ? @_ : @{ $self->{config} };

    return Data::Remember::_init_brain(@config);
}

=head2 remember QUE, FACT

Stores C<FACT> into C<QUE> for the brain in the current POE session.

=cut

sub remember {
    my $self = shift;
    my $que  = shift;
    my $fact = shift;

    return POE::Kernel->get_active_session->get_heap->remember($que, $fact); 
}

=head2 recall QUE

Fetches the fact that has been stored in C<QUE> for the brain in the current POE session heap.

=cut

sub recall {
    my $self = shift;
    my $que  = shift;

    return POE::Kernel->get_active_session->get_heap->recall($que);
}

=head2 forget QUE

Deletes any fact that has been stored in C<QUE> for the brain in the current POE session heap.

=cut

sub forget {
    my $self = shift;
    my $que  = shift;

    return POE::Kernel->get_active_session->get_heap->forget($que);
}

=head2 brain

Returns the brain stored in the current session heap, in case you need to call any brain methods there.

=cut

sub brain {
    my $self = shift;

    return POE::Kernel->get_active_session->get_heap;
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
