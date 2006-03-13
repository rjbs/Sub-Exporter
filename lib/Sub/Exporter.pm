package Sub::Exporter;

use strict;
use warnings;

use Carp ();
use Sub::Install;

=head1 NAME

Sub::Exporter - a sophisticated exporter for custom-built routines

=head1 VERSION

version 0.90

  $Id$

=cut

our $VERSION = '0.90';

=head1 SYNOPSIS

Sub::Exporter provides features from the simple and familiar:

  use Tools::Power;
  # import the default exports of Tools::Power

  use Tools::Power qw(drill circsaw);
  # import two routines from Tools::Power

...to the slightly more esoteric:

  use Tools::Power 'drill', circsaw => { -as => 'buzzsaw' };
  # import the "drill" routine as well as "circsaw", but call it "buzzsaw"

  use Tools::Power drill => { bit => 'masonry', -as => 'masonry_drill' };
  # import a customized version of the "drill" routine

Or:

  use Tools::Power ':manual', defaults => { unbreakable => 1 };
  # import the "manual" group of routines, building in the given defaults

  use Tools::Power brand_preference => [ qw(craftsman park) ];
  # import the usual tools, with the given brand preferences

=head1 USAGE

=head2 What's an Exporter?

First, a quick refresher:  when you C<use> a module, first it is required, then
its C<import> method is called.  The Perl documentation tells us that the
following two lines are equivalent:

  use Module LIST;

  BEGIN { require Module; Module->import(LIST); }

The import method is the module's I<exporter>.

=head2 The Basics of Sub::Exporter

Sub::Exporter builds a custom exporter which can then be installed into your
module.  It builds this method based on configuration passed to its
C<setup_exporter> method.

A very basic use case might look like this:

  package Addition;
  use Sub::Exporter;
  Sub::Exporter::setup_exporter({ exports => [ qw(plus) ]});

  sub plus { my ($x, $y) = @_; return $x + $y; }

This would mean that when someone used your Addition module, they could have
its C<plus> routine imported into their package:

  use Addition qw(plus);

  my $z = plus(2, 2); # this works, because now plus is in the main package

That syntax to set up the exporter, above, is a little verbose, so for the
simple case of just naming some exports, you can write this:

  package Addition;
  use Sub::Exporter -setup => qw(plus);

That is really the same as this:

  use Sub::Exporter -setup => { exports => [ qw(plus) ] };

...which is, in turn, the same as the original example -- except that now the
exporter is built and installed at compile time.  Well, that and you typed
less.

=head2 Using Export Groups

You can specify whole groups of things that should be exportable together.
These are called groups.  L<Exporter> calls these tags.  To specify groups, you
just pass a C<groups> key in your exporter configuration:

  package Food;
  use Sub::Exporter -setup => {
    exports => [ qw(apple banana beef fluff lox rabbit) ],
    groups  => {
      fauna  => [ qw(beef lox rabbit) ],
      flora  => [ qw(apple banana) ],
    }
  };

Now, to import all that delicious foreign meat, your consumer needs only to
write:

  use Food qw(:fauna);
  use Food qw(-fauna);

Either one of the above is acceptable.  A colon is more traditional, but
barewords with a leading colon can't be enquoted by a fat arrow.  We'll see why
that matters later on.

Groups can contain other groups.  If you include a group name (with the leading
dash or colon) in a group definition, it will be expanded recursively when the
exporter is called.  The exporter will B<not> recurse into the same group twice
while expanding groups.

There are two special groups:  C<all> and C<default>.  The C<all> group is
defined by default, and contains all exportable subs.  You can redefine it,
if you want to export only a subset when all exports are requested.  The
C<default> group is the set of routines to export when nothing specific is
requested.  By default, there is no C<default> group.

=head2 Renaming Your Imports

Sometimes you want to import something, but you don't like the name as which
it's imported.  Sub::Exporter can rename your imports for you.  If you wanted
to import C<lox> from the Food package, but you don't like the name, you could
write this:

  use Food lox => { -as => 'salmon' };

Now you'd get the C<lox> routine, but it would be called salmon in your
package.  You can also rename entire groups by using the C<prefix> option:

  use Food -fauna => { -prefix => 'cute_little_' };

Now you can call your C<cute_little_rabbit> routine.  (You can also call
C<cute_little_beef>, but that hardly seems as enticing.)

When you define groups, you can include renaming.

  use Sub::Exporter -setup => {
    exports => [ qw(apple banana beef fluff lox rabbit) ],
    groups  => {
      fauna  => [ qw(beef lox), rabbit => { -as => 'coney' } ],
    }
  };

A prefix on a group like that does the right thing.  This is when it's useful
to use a dash instead of a colon to indicate a group: you can put a fat arrow
between the group and its arguments, then.

  use Food -fauna => { -prefix => 'lovely_' };

  eat( lovely_coney ); # this works

Prefixes also apply recursively.  That means that this code works:

  use Sub::Exporter -setup => {
    exports => [ qw(apple banana beef fluff lox rabbit) ],
    groups  => {
      fauna   => [ qw(beef lox), rabbit => { -as => 'coney' } ],
      allowed => [ -fauna => { -prefix => 'willing_' }, 'banana' ],
    }
  };

  ...

  use Food -allowed => { -prefix => 'any_' };

  $dinner = any_willing_coney; # yum!

Groups can also be passed a C<-suffix> argument.

Finally, if the C<-as> argument to an exported routine is a reference to a
scalar, a reference to the routine will be placed in that scalar.

=head2 Building Subroutines to Order

Sometimes, you want to export things that you don't have on hand.  You might
want to offer customized routines built to the specification of your consumer;
that's just good business!  With Sub::Exporter, this is easy.

To offer subroutines to order, you need to provide a generator when you set up
your exporter.  A generator is just a routine that returns a new routine.
L<perlref> is talking about these when it discusses closures and function
templates. The canonical example of a generator builds a unique incrementor;
here's how you'd do that with Sub::Exporter;

  package Package::Counter;
  use Sub::Exporter -setup => {
    exports => [ counter => sub { my $i = 0; sub { $i++ } } ],
    groups  => { default => [ qw(counter) ] },
  };

Now anyone can use your Package::Counter module and he'll receive a C<counter>
in his package.  It will count up by one, and will never interfere with anyone
else's counter.

This isn't very useful, though, unless the consumer can explain what he wants.
This is done, in part, by supplying arguments when importing.  The following
example shows how a generator can take and use arguments:

  package Package::Counter;

  sub _build_counter {
    my ($class, $arg) = @_;
    $arg ||= {};
    my $i = $arg->{start} || 0;
    return sub { $i++ };
  }

  use Sub::Exporter -setup => {
    exports => [ counter => \&_build_counter ],
    groups  => { default => [ qw(counter) ] },
  };

Now, the consumer can (if he wants) specify a starting value for his counter:

  use Package::Counter counter => { start => 10 };

Arguments to a group are passed along to the generators of routines in that
group, but Sub::Exporter arguments -- anything beginning with a dash -- are
never passed in.  When groups are nested, the arguments are merged as the
groups are expanded.

When a generator is called, it is passed four parameters:

=over

=item * the class on which the exporter was called

=item * the name of the export being generated (not the name it's being installed as)

=item * the arguments supplied for the routine

=item * the collection of generic arguments

=back

The third item is the last major feature that hasn't been covered.

=head2 Argument Collectors

Sometimes you will want to accept arguments once that can then be available to
any subroutine that you're going to export.  To do this, you specify
collectors, like this:

  use Menu::Airline
  use Sub::Exporter -setup => {
    exports =>  ... ,
    groups  =>  ... ,
    collectors => [ qw(allergies ethics) ],
  };

Collectors look like normal exports in the import call, but they don't do
anything but collect data which can later be passed to generators.  If the
module was used like this:

  use Menu::Airline allergies => [ qw(peanuts) ], ethics => [ qw(vegan) ];

...the consumer would get a salad.  Also, all the generators would be passed,
as their third argument, something like this:

  { allerges => [ qw(peanuts) ], ethics => [ qw(vegan) ] }

Generators may have arguments in their definition, as well.  These must be code
refs that perform validation of the collected values.  They are passed the
collection value and may return true or false.  If they return false, the
exporter will throw an exception.

=head2 Generating Many Routines in One Scope

Sometimes it's useful to have multiple routines generated in one scope.  This
way they can share lexical data which is otherwise unavailable.  To do this,
you can supply a generator for a group which returns a hashref of names and
code references.  This generator is passed all the usual data, and the group
may receive the usual C<-prefix> or C<-suffix> arguments.

=cut

# This produces an array of arrays; the inner arrays are name/value pairs.
# Values will be either "undef" or a reference.  $must_be is either a scalar or
# array of scalars; it defines what kind(s) of refs may be values.  If an
# invalid value is found, an exception is thrown.
# possible inputs:
#  undef    -> []
#  hashref  -> [ [ key1 => value1 ] ... ] # non-ref values become undef
#  arrayref -> every value followed by a ref becomes a pair: [ value => ref   ]
#              every value followed by undef becomes a pair: [ value => undef ]
#              otherwise, it becomes [ value => undef ] like so:
#              [ "a", "b", [ 1, 2 ] ] -> [ [ a => undef ], [ b => [ 1, 2 ] ] ]
sub _canonicalize_opt_list {
  my ($opt_list, $require_unique, $must_be) = @_;

  return [] unless $opt_list;

  $opt_list = [
    map { $_ => (ref $opt_list->{$_} ? $opt_list->{$_} : ()) } keys %$opt_list
  ] if ref $opt_list eq 'HASH';

  my @return;

  for (my $i = 0; $i < @$opt_list; $i++) {
    my $name = $opt_list->[$i];
    my $value;

    if    ($i == $#$opt_list)             { $value = undef;            }
    elsif (not defined $opt_list->[$i+1]) { $value = undef; $i++       }
    elsif (ref $opt_list->[$i+1])         { $value = $opt_list->[++$i] }
    else                                  { $value = undef;            }

    if ($must_be and defined $value) {
      $must_be = [ $must_be ] unless ref $must_be;
      my $ref = ref $value;
      Carp::croak "$ref-ref values are not allowed"
        unless grep { $ref eq $_ } @$must_be;
    }

    push @return, [ $name => $value ];
  }

  if ($require_unique) {
    my %seen;
    map { Carp::croak "multiple definitions provided for $_" if $seen{$_}++ }
    map { $_->[0] } @return;
  }

  return \@return;
}

# This turns a canonicalized opt_list (see above) into a hash.
sub _expand_opt_list {
  my ($opt_list, $must_be) = @_;
  return {} unless $opt_list;
  return $opt_list if ref $opt_list eq 'HASH';

  $opt_list = _canonicalize_opt_list($opt_list, 1, $must_be);
  my %hash = map { $_->[0] => $_->[1] } @$opt_list;
  return \%hash;
}

# Given a potential import name, this returns the group name -- if it's got a
# group prefix.
sub _group_name {
  my ($name) = @_;

  return unless $name =~ s/\A[-:]//;
  return $name;
}

# \@groups is a canonicalized opt list of exports and groups this returns
# another canonicalized opt list with groups replaced with relevant exports.
# \%seen is groups we've already expanded and can ignore.
# \%merge is merged options from the group we're descending through.
sub _expand_groups {
  my ($class, $config, $groups, $collection, $seen, $merge) = @_;
  $seen  ||= {};
  $merge ||= {};

  my @groups = @$groups;

  for my $i (reverse 0 .. $#$groups) {
    # this isn't a group, let it be
    if (my $group_name = _group_name($groups[$i][0])) {
      # we already dealt with this, remove it
      if ($seen->{ $group_name }) {
        splice @groups, $i, 1;
        next;
      }

      # rewrite the group
      splice @groups, $i, 1,
        _expand_group($class, $config, $groups[$i], $collection, $seen, $merge);
    } else {
      next unless my %merge = %$merge;
      my $prefix = (delete $merge{-prefix}) || '';
      my $suffix = (delete $merge{-suffix}) || '';
      if (ref $groups[$i][1] eq 'CODE') {
         $groups[$i][0] = $prefix . $groups[$i][0] . $suffix;
      } else {
        my $as = ref $groups[$i][1]{-as}
          ? $groups[$i][1]{-as}
          : $prefix . ($groups[$i][1]{-as}||$groups[$i][0]) . $suffix;
        $groups[$i][1] = { %{ $groups[$i][1] }, %merge, -as => $as };
      }
    }
  }

  return \@groups;
}

# \@group is a name/value pair from an opt list.
sub _expand_group {
  my ($class, $config, $group, $collection, $seen, $merge) = @_;
  $merge ||= {};

  my ($group_name, $group_arg) = @$group;
  $group_name = _group_name($group_name);

  if (ref $group_arg) {
    my $prefix = (delete $merge->{-prefix}||'') . ($group_arg->{-prefix}||'');
    my $suffix = ($group_arg->{-suffix}||'') . (delete $merge->{-suffix}||'');
    $merge = {
      %$merge,
      %$group_arg,
      ($prefix ? (-prefix => $prefix) : ()),
      ($suffix ? (-suffix => $suffix) : ()),
    };
  }

  Carp::croak qq(group "$group_name" is not exported by the $class module)
    unless exists $config->{groups}{$group_name};

  $seen->{$group_name} = 1;
  
  my $exports = $config->{groups}{$group_name};

  if (ref $exports eq 'CODE') {
    my $group = $exports->($class, $group_name, $group_arg, $collection);
    Carp::croak qq(group generator "$group_name" did not return a hashref)
      if ref $group ne 'HASH';
    my $stuff = [ map { [ $_ => $group->{$_} ] } keys %$group ];
    return @{
      _expand_groups($class, $config, $stuff, $collection, $seen, $merge)
    };
  } else {
    $exports = _canonicalize_opt_list($exports);

    return @{
      _expand_groups($class, $config, $exports, $collection, $seen, $merge)
    };
  }
}

# Given a config and pre-canonicalized importer args, remove collections from
# the args and return them.
sub _collect_collections {
  my ($config, $import_args) = @_;
  my %collection;

  for my $collection (keys %{ $config->{collectors} }) {
    next unless my @indexes
      = grep { $import_args->[$_][0] eq $collection } (0 .. $#$import_args);

    Carp::croak "collection $collection provided multiple times in import"
      if @indexes > 1;

    my $value = splice @$import_args, $indexes[0], 1;
    $collection{ $collection } = $value->[1];

    if (ref(my $validator = $config->{collectors}{$collection})) {
      Carp::croak "collection $collection failed validation"
        unless $validator->($collection{$collection});
    }
  }

  return \%collection;
}

=head1 SUBROUTINES

=head2 C< setup_exporter >

This routine builds and installs an C<import> routine.  It is called with one
argument, a hashref containing the exporter configuration.  Using this, it
builds an exporter and installs it into the calling package with the name
"import."  In addition to the normal exporter configuration, two named
arguments may be passed in the hashref:

  into - into what package should the exporter be installed (defaults to caller)
  as   - what name should the installed exporter be given (defaults to "import")

The exporter is built by C<L</build_exporter>>.

=cut

# \%special is for experimental options that may or may not be kept around and,
# probably, moved to \%config.  These are also passed along to build_exporter.

sub setup_exporter {
  my ($config, $special)  = @_;
  $special ||= {};

  my $into = delete $config->{into} || caller(0);
  my $as   = delete $config->{as}   || 'import';

  my $import = build_exporter($config, $special);

  Sub::Install::install_sub({
    code => $import,
    into => $into,
    as   => $as,
  });
}

=head2 C< build_exporter >

Given a standard exporter configuration, this routine builds and returns an
exporter -- that is, a subroutine that can be installed as a class method to
perform exporting on request.

Usually, this method is called by C<L</setup_exporter>>, which then installs
the exporter as a package's import routine.

=cut

sub build_exporter {
  my ($config, $special) = @_;
  $special ||= {};

  # this option name, if nothing else, needs to be improved before it is
  # accepted as a core feature -- rjbs, 2006-03-09
  $special->{export} ||= \&_export;
  
  $config->{$_} = _expand_opt_list($config->{$_}, 'CODE')
    for qw(exports collectors);

  $config->{groups} = _expand_opt_list($config->{groups}, [ 'HASH', 'CODE' ]);

  # by default, export nothing
  $config->{groups}{default} ||= [];

  # by default, build an all-inclusive 'all' group
  $config->{groups}{all} ||= [ keys %{ $config->{exports} } ];

  my $import = sub {
    my ($class) = shift;
    my ($into)  = caller(0);

    # this builds a AOA, where the inner arrays are [ name => value_ref ]
    my $import_args = _canonicalize_opt_list([ @_ ]);
    
    my $collection = _collect_collections($config, $import_args);

    $import_args = [ [ -default => 1 ] ] unless @$import_args;
    my $to_import = _expand_groups($class, $config, $import_args, $collection);

    # now, finally $import_arg is really the "to do" list
    for (@$to_import) {
      my ($name, $arg) = @$_;

      my ($generator, $as);

      if ($arg and ref $arg eq 'CODE') {
        $generator = sub { $arg };
        $as = $name;
      } else {
        $arg = { $arg ? %$arg : () };

        Carp::croak qq("$name" is not exported by the $class module)
          unless (exists $config->{exports}{$name});

        $generator = $config->{exports}{$name};

        $as = exists $arg->{-as} ? (delete $arg->{-as}) : $name;
      }

      $special->{export}->(
        $class, $generator, $name, $arg, $collection, $as, $into
      );
    }
  };

  return $import;
}

# like build_exporter, but if passed a non-reference, it treats its arguments
# as a list of exports.
sub _polymorphic_build_exporter {
  if (ref $_[0]) {
    return build_exporter(@_);
  } else {
    return build_exporter({ exports => [ @_ ] });
  }
}

# the default installer; it does what Sub::Exporter promises: call generators
# with the three normal arguments, then install the code into the target
# package
sub _export {
  my ($class, $generator, $name, $arg, $collection, $as, $into) = @_;
  _install(
    _generate($class, $generator, $name, $arg, $collection, $as, $into),
    $into,
    $as,
  );
}

sub _generate {
  my ($class, $generator, $name, $arg, $collection, $as, $into) = @_;

  my $code = $generator
           ? $generator->($class, $name, $arg, $collection)
           : $class->can($name); 
}

sub _install {
  my ($code, $into, $as) = @_;
  # Allow as isa ARRAY to push onto an array?
  # Allow into isa HASH to install name=>code into hash?

  if (ref $as eq 'SCALAR') {
    $$as = $code;
  } elsif (ref $as) {
    Carp::croak "invalid reference type for $as: " . ref $as;
  } else {
    Sub::Install::install_sub({ code => $code, into => $into, as => $as });
  }
}

=head1 EXPORTS

Sub::Exporter also offers its own exports: the C<setup_exporter> and
C<build_exporter> routines described above.  It also provides a special "setup"
group, which will setup an exporter using the parameters passed to it.  This
group can be passed a list of subroutines names to export, instead of the
normal configuration hash.

=cut

setup_exporter({
  exports => [
    qw(setup_exporter build_exporter),
    _import => sub { splice @_, 0, 2; _polymorphic_build_exporter(@_) },
  ],
  groups  => {
    all   => [ qw(setup_exporter build_export) ],
    setup => { _import => { -as => 'import' } }
  }
});

=head1 TODO

=cut

# This would be cool:
# use Food qr/\Aartificial/ => { -prefix => 'non_' };

# This is, I think, nearly a necessity:
# a way to have one generator provide several routines which can then be
# installed together
# maybe:
# groups => { encode => sub { (returns hashref) } };

=over

=item * write a set of longer, more demonstrative examples

=item * solidify the "custom build and install" interface (see &_export)

=back

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 THANKS

Hans Dieter Pearcey and Shawn Sorichetti both provided helpful advice while I
was writing Sub::Exporter.  Thanks, guys!

=head1 BUGS

Please report any bugs or feature requests to C<bug-sub-exporter@rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org>. I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 SEE ALSO

There are a whole mess of exporters on the CPAN.  Here's a quick summary:

=over

=item * L<Exporter> and co.

This is the standard Perl exporter.  Its interface is a little clunky, but it's
fast and ubiquitous.  It can do some things that Sub::Exporter can't.  It can
export things other than routines, it can import "everything in this group
except this symbol," and some other more esoteric things.

It always exports things exactly as they appear in the exporting module; it
can't rename or customize routines.  Its groups ("tags") can't be nested.

L<Exporter::Lite> is a whole lot like Exporter, but it does significantly less.

L<Exporter::Easy> provides a wrapper around the standard Exporter.

=item * Attribute-Based Exporters

Some exporters use attributes to mark variables to export.  L<Exporter::Simple>
supports exporting any kind of symbol, and supports groups.

L<Perl6::Export> isn't actually attribute based, but looks similar.  Its syntax
is borrowed from Perl 6, and implemented by a source filter.

=item * Other Exporters

L<Exporter::Renaming> wraps the standard Exporter to allow it to export symbols
with changed names.

L<Class::Exporter> performs a special kind of routine generation, giving each
importing package an instance of your class, and then exporting the instance's
methods as normal routines.  (Sub::Exporter, of course, can easily emulate this
behavior.)

L<Exporter::Tidy> implements a form of renaming (using its C<_map> argument)
and of prefixing, and implements groups.  It also avoids using package
variables for its configuration.

=back

=head1 COPYRIGHT

Copyright 2006 Ricardo SIGNES.  This program is free software;  you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

"jn8:32"; # <-- magic true value
