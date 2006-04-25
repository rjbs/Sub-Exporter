use strict;
use warnings;

package Sub::Exporter::Util;

=head1 NAME

Sub::Exporter::Util - utilities to make Sub::Exporter easier

=head1 VERSION

version 0.01

  $Id$

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This module provides a number of utility functions for performing common or
useful operations when setting up a Sub::Exporter configuration.  All of the
utilites may be exported, but none are by default.

=head1 THE UTILITIES

=head2 curry_class

  exports => {
    some_method => curry_class,
  }

This utility returns a generator which will produce a class-curried version of
a method.  In other words, it will export a method call with the exporting
class built in as the invocant.

A module importing the code some the above example might do this:

  use Some::Module qw(some_method);

  my $x = some_method;

This would be equivalent to:

  use Some::Module;

  my $x = Some::Module->some_method;

If Some::Module is subclassed and the subclass's import method is called to
import C<some_method>, the subclass will be curried in as the invocant.

=cut

sub curry_class {
  sub {
    my ($class, $name) = @_;
    sub { $class->$name(@_); };
  }
}

=head2 merge_col

  exports => {
    merge_col(defaults => {
      twiddle => \&_twiddle_gen,
      tweak   => \&_tweak_gen,
    }),
  }

This utility wraps the given generator in one that will merge the named
collection into its args before calling it.  This means that you can support a
"default" collector in multipe exports without writing the code each time.

=cut

sub merge_col {
  my (%groups) = @_;

  my %merged;

  while (my ($default_name, $group) = each %groups) {
    while (my ($export_name, $gen) = each %$group) {
      $merged{$export_name} = sub {
        my ($class, $name, $arg, $col) = @_;

        my $merged_arg = exists $col->{$default_name}
                       ? { %{ $col->{$default_name} }, %$arg }
                       : $arg;

        $gen->($class, $name, $merged_arg, $col);
      }
    }
  }

  return %merged;
}

=head2 mixin_exporter

  use Sub::Exporter -setup => {
    exporter => Sub::Exporter::Util::mixin_exporter,
    exports  => [ qw(foo bar baz) ],
  };

This utility returns an exporter that will export into a superclass and adjust
the ISA importing class to include the newly generated superclass.

B<Prerequisites>: This utility requires that Package::Generator be installed.

=cut

sub mixin_exporter {
  my ($mixin_class, $col_ref);
  sub {
    my ($class, $generator, $name, $arg, $collection, $as, $into) = @_;

    unless ($mixin_class and ($collection == $col_ref)) {
      require Package::Generator;
      $mixin_class = Package::Generator->new_package({
        base => "$class\:\:__mixin__",
      });
      $col_ref = 0 + $collection;
      no strict 'refs';
      unshift @{"$into" . "::ISA"}, $mixin_class;
    }
    $into = $mixin_class;
    Sub::Exporter::default_exporter(
      $class, $generator, $name, $arg, $collection, $as, $into
    );
  };
}

=head2 like

It's a collector that adds imports for anything like given regex.

If you provide this configuration:

  exports    => [ qw(igrep imap islurp exhausted) ],
  collectors => { -like => Sub::Exporter::Util::like },

A user may import from your module like this:

  use Your::Iterator -like => qr/^i/; # imports igre, imap, islurp

or

  use Your::Iterator -like => [ qr/^i/ => { -prefix => 'your_' } ];

The group-like prefix and suffix arguments are respected; other arguments are
passed on to the generators for matching exports.

=cut

sub like {
  sub {
    my ($value, $arg) = @_;
    Carp::croak "no regex supplied to regex group generator" unless $value;

    # Oh, qr//, how you bother me!  See the p5p thread from around now about
    # fixing this problem... too bad it won't help me. -- rjbs, 2006-04-25
    my @values = eval { $value->isa('Regexp') } ? ($value, undef)
               :                                  @$value;

    while (my ($re, $opt) = splice @values, 0, 2) {
      Carp::croak "given pattern for regex group generater is not a Regexp"
        unless eval { $re->isa('Regexp') };
      my @exports  = keys %{ $arg->{config}->{exports} };
      my @matching = grep { $_ =~ $re } @exports;

      my %merge = $opt ? %$opt : ();
      my $prefix = (delete $merge{-prefix}) || '';
      my $suffix = (delete $merge{-suffix}) || '';

      for my $name (@matching) {
        my $as = $prefix . $name . $suffix;
        push @{ $arg->{import_args} }, [ $name => { %merge, -as => $as } ];
      }
    }

    1;
  }
}

use Sub::Exporter -setup => {
  exports => [ qw(like merge_col curry_class mixin_exporter) ]
};

=head1 TODO

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sub-exporter@rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org>. I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 COPYRIGHT

Copyright 2006 Ricardo SIGNES.  This program is free software;  you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
