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

Sub::Exporter must be used in two places.  First, in an exporting module:

  # in the exporting module:
  package Text::Tweaker;
  use Sub::Exporter -setup => {
    exports => [
      qw(squish titlecase) # always works the same way
      reformat => \&build_reformatter, # generator to build exported function
      trim     => \&build_trimmer,
      indent   => \&build_indenter,
    ],
    groups  => {
      default    => [ qw(reformat) ],
      shorteners => [ qw(squish trim) ],
      email_safe => [
        'indent',
        reformat => { -as => 'email_format', width => 72 }
      ],
    },
    collectors => [ 'defaults' ],
  };

Then, in an importing module:

  # in the importing module:
  use Text::Tweaker
    -shorteners => { -prefix => 'text_' },
    reformat    => { width => 79, justify => 'full', -as => 'prettify_text' },
    defaults    => { eol => 'CRLF' };

With this setup, the importing module ends up with three routines:
C<text_squish>, C<text_trim>, and C<prettify_text>.  The latter two have been
built to the specifications of the importer -- they are not just copies of the
code in the exporting package.

=head1 DESCRIPTION

B<ACHTUNG!>  If you're not familiar with Exporter or exporting, read
L<Sub::Exporter::Tutorial> first!

=head2 Why Generators?

The biggest benefit of Sub::Exporter over existing exporters (including the
ubiquitous Exporter.pm) is its ability to build new coderefs for export, rather
than to simply export code identical to that found in the exporting package.

If your module's consumers get a routine that works like this:

  use Data::Analyze qw(analyze);
  my $value = analyze($data, $tolerance, $passes);

and they constantly pass only one or two different set of values for the
non-C<$data> arguments, your code can benefit from Sub::Exporter.  By writing a
simple generator, you can let them do this, instead:

  use Data::Analyze
    analyze => { tolerance => 0.10, passes => 10, -as => analyze10 },
    analyze => { tolerance => 0.15, passes => 50, -as => analyze50 };

  my $value = analyze10($data);

The generator for that would look something like this:

  sub build_analyzer {
    my ($class, $name, $arg) = @_;

    return sub {
      my $data      = shift;
      my $tolerance = shift || $arg->{tolerance}; 
      my $passes    = shift || $arg->{passes}; 

      analyze($data, $tolerance, $passes);
    }
  }

Your module's user now has to do less work to benefit from it -- and remember,
you're often your own user!  Investing in customized subroutines is an
investment in future laziness.

This also avoids a common form of ugliness seen in many modules: package-level
configuration.  That is, you might have seen something like the above
implemented like so:

  use Data::Analyze qw(analyze);
  $Data::Analyze::default_tolerance = 0.10;
  $Data::Analyze::default_passes    = 10;

This might save time, until you have multiple modules using Data::Analyze.
Because there is only one global configuration, they step on each other's toes
and your code begins to have mysterious errors.

=head2 Other Customizations

Building custom routines with generators isn't the only way that Sub::Exporters
allows the importing code to refine its use of the exported routines.  They may
also be renamed to avoid naming collisions.

Consider the following code:

  # this program determines to which circle of Hell you will be condemned
  use Morality qw(sin virtue); # for calculating viciousness
  use Math::Trig qw(:all);     # for dealing with circles

The programmer has inadvertantly imported two C<sin> routines.  The solution,
in Exporter.pm-based modules, would be to import only one and then call the
other by its fully-qualified name.  Alternately, the importer could write a
routine that did so, or could mess about with typeglobs.

How much easier to write:

  # this program determines to which circle of Hell you will be condemned
  use Morality qw(virtue), sin => { -as => 'offense' };
  use Math::Trig -all => { -prefix => 'trig_' };

and to have at one's disposal C<offense> and C<trig_sin>.

=head1 EXPORTER CONFIGURATION

You can configure an exporter for your package by using Sub::Exporter like so:

  package Tools;
  use Sub::Exporter -setup => qw(function1 function2 function3);

This is the simplest way to use the exporter, and is basically equivalent to
this:

  package Tools;
  use base qw(Exporter);
  our @EXPORT_OK = qw(function1 function2 function2);

To benefit from most of Sub::Exporter's features, this form must be used
instead:

  package Tools;
  use Sub::Exporter -setup => \%config;

The following keys are valid in C<%config>:

  exports - a list of routines to provide for exporting; each routine may be
            followed by generator
  groups  - a list of groups to provide for exporting; each must be followed by
            a list of exports, possibly with arguments for each export
  collectors - a list of names into which values are collected for use in
               routine generation; each name may be followed by a validator

=head2 C<exports> Configuration

The C<exports> list may be provided as an array reference or a hash reference.
The list is processed in such a way that the following are equivalent:

  { exports => [ qw(foo bar baz), quux => \&quuz_generator ] }

  { exports =>
    { foo => undef, bar => undef, baz => undef, quux => \&quuz_generator } }

Generators are coderefs that return coderefs.  They are called with four
parameters:

  $class - the class whose exporter has been called (the exporting class)
  $name  - the name of the export for which the routine is being build
 \%arg   - the arguments passed for this export
 \%coll  - the collections for this import

Given the configuration in the L</SYNOPSIS>, the following C<use> statement:

  use Text::Tweaker
    reformat => { -as => 'make_narrow', width => 33 },
    defaults => { eol => 'CR' };

would result in the following call to C<&build_reformatter>:

  my $code = build_reformatter(
    'Text::Tweaker',
    'reformat',
    { width => 33 }, # note that -as is not passed in
    { defaults => { eol => 'CR' } },
  );

The returned coderef (<$code>) would then be installed as C<make_narrow> in the
calling package.

=head2 C<groups> Configuration

The C<groups> list can be passed in the same forms as C<exports>.  Groups must
have values to be meaningful, which may either list exports that make up the
group (optionally with arguments) or may provide a way to build the group.

The simpler case is the first: a group definition is a list of exports.  Here's
the example from the L</SYNOPSIS>.

  groups  => {
    default    => [ qw(reformat) ],
    shorteners => [ qw(squish trim) ],
    email_safe => [
      'indent',
      reformat => { -as => 'email_format', width => 72 }
    ],
  },

Groups are imported by specifying their name prefixed be either a dash or a
colon.  This line of code would import the C<shorteners> group:

  use Text::Tweaker qw(-shorteners);

Arguments passed to a group when importing are merged into the groups options
and passed to any relevant generators.  Groups can contain other groups, but
looping group structures are ignored.

The other possible value for a group definition, a coderef, allows one
generator to build several exportable routines simultaneously.  This is useful
when many routines must share enclosed lexical variables.  The coderef must
return a hash reference.  The keys will be used as export names and the values
are the subs that will be exported.

This example shows a simple use of the group generator.

  package Data::Crypto;
  use Sub::Exporter -setup => { groups => { cipher => \&build_cipher_group } };

  sub build_cipher_group {
    my ($class, $group, $arg) = @_;
    my ($encode, $decode) = build_codec($arg->{secret});
    return { cipher => $encode, decipher => $decode };
  }

The C<cipher> and C<decipher> routines are built in a group because they are
built together by code which encloses their secret in their environment.

=head2 C<collectors> Configuration

The C<collectors> entry in the exporter configuration gives names which, when
found in the import call, have their values collected and passed to every
generator.

For example, the C<build_analyzer> generator that we saw above could be
rewritten as:

 sub build_analyzer {
   my ($class, $name, $arg, $col) = @_;

   return sub {
     my $data      = shift;
     my $tolerance = shift || $arg->{tolerance} || $col->{defaults}{tolerance}; 
     my $passes    = shift || $arg->{passes}    || $col->{defaults}{passes}; 

     analyze($data, $tolerance, $passes);
   }
 }

That would allow the import to specify global defaults for his imports:

  use Data::Analyze
    'analyze',
    analyze  => { tolerance => 0.10, -as => analyze10 },
    analyze  => { tolerance => 0.15, passes => 50, -as => analyze50 },
    defaults => { passes => 10 };

  my $A = analyze10($data);     # equivalent to analyze($data, 0.10, 10);
  my $C = analyze50($data);     # equivalent to analyze($data, 0.15, 10);
  my $B = analyze($data, 0.20); # equivalent to analyze($data, 0.20, 10);

If values are provided in the C<collectors> list during exporter setup, they
must be code references, and are used to validate the importer's values.  The
validator is called when the collection is found, and if it returns false, an
exception is thrown.  We could ensure that no one tries to set a global data
default easily:

  collectors => { defaults => sub { return (exists $_[0]->{data}) ? 0 : 1 } }

=head1 CALLING THE EXPORTER

Arguments to the exporter (that is, the arguments after the module name in a
C<use> statement) are parsed as follows:

First, the collectors gather any collections found in the arguments.  Any
reference type may be given as the value for a collector.  For each collection
given in the arguments, its validator (if any) is called.  

Next, groups are expanded.  If the group is implemented by a group generator,
the generator is called.  There are two special arguments which, if given to a
group, have special meaning:

  -prefix - a string to prepend to any export imported from this group
  -suffix - a string to append to any export imported from this group

Finally, individual export generators are called and all subs, generated or
otherwise, are installed in the calling package.  There is only one special
argument for export generators:

  -as     - where to install the exported sub

Normally, C<-as> will contain an alternate name for the routine.  It may,
however, contain a reference to a scalar.  If that is the case, a reference the
generated routine will be placed in the scalar referenced by C<-as>.  It will
not be installed into the calling package.

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
was writing Sub::Exporter.  Ian Langworth asked some good questions and hepled
me improve my documentation.  Thanks, guys!

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
