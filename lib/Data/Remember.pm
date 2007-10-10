use strict;
use warnings;

package Data::Remember;

our $VERSION = '0.05';

use Carp;
use UNIVERSAL::require;

=head1 NAME

Data::Remember - remember complex information without giving yourself a headache

=head1 SYNOPSIS

  use Data::Remember 'Memory';

  remember foo => 1;
  remember [ bar => 7 ], [ 'spaz', 'w00t', 'doof', 'flibble' ];
  remember [ 'xyz', 'abc', 'mno' ] => { some => 'thing' };

  my $foo     = recall 'foo';        # retrieve a simple key
  my $wibbler = recall [ bar => 7 ]; # retrieve a complex key
  my $alpha   = recall 'xyz';        # retrieve a subkey

  forget 'foo';

=head1 DESCRIPTION

While designing some IRC bots and such I got really tired of statements that looked like:

  $heap->{job}{$job} = {
      source  => $source,
      dest    => $destination,
      options => $options,
  };

and later:

  if ($heap->{job}{$job}{options}{wibble} eq $something_else) {
      # do something...
  }

I could simplify things with intermediate variables, but then I inevitably end up with 4 or 5 lines of init at the start or middle of each subroutine. Yech.

So, I decided that it would be nice to simplify the above to:

  remember [ job => $job ], {
      source  => $source,
      dest    => $destination,
      options => $options,
  };

and later:

  if (recall [ job => $job, options => 'wibble' ] eq $something_else) {
      # do something...
  }

Which I consider to far more readable.

The second aspect that this deals with is long-term storage. I started using L<DBM::Deep> to remember the important bits of state across bot restarts. This package will store your information persistently for you too if you want:

  use Data::Remember DBM => 'state.db';

By using that command, the L<Data::Remember::DBM> "brain" is used instead of the usual L<Data::Remember::Memory> brain, which just stores things in a Perl data structure.

=head1 SUBROUTINES

By using this module you will automatically import (I know, how rude) four subroutines into the calling package: L</remember>, L</recall>, L</forget>, and L</brain>.

=head2 QUE

Each take a C<$que> argument. The que is a memory que to store the information with. This que may be a scalar, an array, or a hash, depending on what suits your needs. However, you will want to be aware of how these are translated into memory locations in the brain plugin.

Any que argument is passed to the brain as an array. A scalar que is just wrapped in an array reference:

  remember foo => 1;

is the same as:

  remember [ 'foo' ] => 1;

An array que is passed exactly as it is to the brain plugin.

A hash que is converted to an array by sorting the keys in lexicographic order and keeping the pairs together. For example:

  remember { foo => 3, bar => 2, baz => 1 } => 'xyz';

is the same as:

  remember [ bar => 2, baz => 1, foo => 3 ] => 'xyz';

Once the array is built the brains are required to treat these in the same way as hash keys for a hash of hashes. For example, you can think of:

  remember [ foo => 3, bar => 2, baz => 1 ] => 'xyz';

as being similar to storing:

  $memory->{foo}{3}{bar}{2}{baz}{1} = 'xyz';

This means that you could later recall a subset of the previous key:

  my $bar = recall [ foo => 3, 'bar' ];

which would return a hash reference similar to:

  my $bar = { 2 => { baz => { 1 => 'xyz' } } };

(assuming you hadn't stored anything else under C<< [ foo => 3, 'bar' ] >>).

Clear as mud? Good!

=head2 import $brain, @options;

Called automagically when you C<use> this package. Do B<NOT> try

  use Data::Remember ();

This will keep import from being called, which will keep you from using any of the nice features of this package. Since it uses deep magic in the import process, attempting to call C<Data::Remember::remember()> and such won't work correctly. 

If you can't import these three methods, sorry. Send me a bug report and a patch and I'll consider it.

The C<$brain> argument lets you select a brain plugin to use. The brain plugins available with this distribution currently include:

=over

=item L<Data::Remember::Memory>

A brain that stores everything in plain Perl data structures. Data in this brain is not persistent.

=item L<Data::Remember::DBM>

A brain that stores everything via L<DBM::Deep>. Data stored here will be persistent. This brain also requires additional arguments (see the module documentation for details).

=item L<Data::Remember::YAML>

A brain that stores everything via L<YAML>. This is great for storing configuration data.

=item L<Data::Remember::Hybrid>

A brain that doesn't store anything, but lets you use mix storage mechanisms.

=back

You can specify C<$brain> as a short name if it exists under "C<Data::Remember::>". (For example, "C<DBM>" will load "C<Data::Remember::DBM>".) if C<$brain> contains a "C<::>", then it will be treated as a fully qualified name, in case you want to create your own brain. See L</CREATING A BRAIN>.

The C<@options> are whatever options described in the brain's module documentation.

=cut

sub import {
    my $class   = shift;
    my $brain   = shift || 'Memory';

    my $caller = caller;

    my $gray_matter = _init_brain($brain, @_);
    $class->_import_brain( $gray_matter => $caller );
}

sub _init_brain {
    my $brain = shift;

    $brain = 'Data::Remember::' . $brain
        unless $brain =~ /::/;

    $brain =~ /^[\w:]+$/ 
        or croak qq{This does not look like a valid brain: $brain};

    $brain->require
        or carp qq{The brain $brain may not have loaded correctly: $@};

    my $gray_matter = $brain->new(@_);

    # Duck typing!
    $gray_matter->can('remember')
        or croak qq{Your brain cannot remember facts: $brain};
    $gray_matter->can('recall')
        or croak qq{Your brain cannot recall facts: $brain};
    $gray_matter->can('forget')
        or croak qq{Your brain cannot forget facts: $brain};

    return $gray_matter;
}

sub _import_brain {
    my $class   = shift;
    my $brain   = shift;
    my $package = shift;

    no strict 'refs';

    *{"$package\::remember"} = remember($brain);
    *{"$package\::recall"}   = recall($brain);
    *{"$package\::forget"}   = forget($brain);
    *{"$package\::brain"}    = brain($brain);
}

sub _process_que {
    my $que = shift;

    my @ques;
    if (ref $que eq 'ARRAY') {
        @ques = @$que;
    }

    elsif (ref $que eq 'HASH') {
        for my $key (sort keys %$que) {
            push @ques, $key, $que->{$key};
        }
    }

    else {
        @ques = ($que);
    }

    return \@ques;
}

=head2 remember $que, $fact

Remember the given C<$fact> at memory que C<$que>. See L</QUE> for an in depth discussion of C<$que>. The C<$fact> can be anything your brain can store. This will generally include, at least, scalars, hash references, and array references.

=cut

sub remember {
    my $brain = shift;

    sub ($$) {
        my $que  = shift;
        my $fact = shift;

        my $clean_que = _process_que($que);;

        $brain->remember($clean_que, $fact);

        return;
    };
}

=head2 recall $que

Recalls a previously stored fact located at the memory location described by C<$que>. See L</QUE> for an in depth discussion of that argument.

If no fact is found at that que, C<undef> will be returned.

=cut

sub recall {
    my $brain = shift;

    sub ($) {
        my $que = shift;

        my $clean_que = _process_que($que);

        return scalar $brain->recall($clean_que);
    };
}

=head2 forget $que

Tells the brain to forget a previously remembered fact stored at C<$que>. See L</QUE> for an in depth discussion of the argument. If no fact is stored at the given C<$que>, this subroutine does nothing.

=cut

sub forget {
    my $brain = shift;

    sub ($) {
        my $que = shift;

        my $clean_que = _process_que($que);

        $brain->forget($clean_que);

        return;
    };
}

=head2 brain

Returns the inner object used to store data. This can be used in case the brain plugin provides additional methods or features that need manual access. For example, if you want to use L<DBM::Deep>s locking features, you could:

  brain->dbm->begin_work;

  my $balance = recall 'balance';
  remember balance => $balance + 150;

  brain->dbm->commit;

=cut

sub brain {
    my $brain = shift;

    sub () { return $brain };
}

=head1 CREATING A BRAIN

If you would like to create a custom brain plugin, you need to create a package that implements four methods: C<new>, C<remember>, C<recall>, and C<forget>.

The C<new> method will take the list of options passed to L</import> for your brain in addition to the class name. It should return a blessed reference that will be used for all further method calls.

The C<remember> method will be passed a normalized reference to a que array and the fact the user has asked to store. You should read through L</QUE> and handle the first argument as described there. Then, store the second argument at the memory location described.

The C<recall> method will be passed a normalized reference to a que array, which should be treated as described in L</QUE>. Your implementation should return the fact stored at that location or C<undef>. It's important that your implementation avoid the pit-falls caused by auto-vivifying keys. The C<recall> method should never modify the memory of your brain.

The C<forget> method will be passed a normalized reference to a que array, which should be treated as described in L</QUE>. Your implementation should then delete any fact stored there. Other than deleting this key, the C<forget> method should not modify any other aspect of the memory of your brain.

To build a brain, I highly recommend extending L<Data::Remember::Memory>, which performs (or should perform) all the work of safely storing and fetching records from a Perl data structure according to the interface described here. It stores everything under C<< $self->{brain} >>. At the very least, you should read through that code before building your brain.

The L<Data::Remember::DBM> or other included brains may also be a good place to look. They extend L<Data::Remember::Memory> so that I didn't have to repeat myself.

=head1 SEE ALSO

L<Data::Remember::Memory>, L<Data::Remember::DBM>, L<Data::Remember::YAML>, L<Data::Remember::Hybrid>

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
