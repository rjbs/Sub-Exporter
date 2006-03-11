#!perl -T
use strict;
use warnings;

=head1 TEST PURPOSE

These tests check the output of build_exporter when handed an alternate
exporter that returns its plan.

=cut

use Test::More tests => 11;

BEGIN { use_ok('Sub::Exporter'); }

my $config = {
  exports => [
    qw(circsaw drill handsaw nailgun),
    hammer => sub { sub { print "BANG BANG BANG\n" } },
  ],
  groups => {
    default => [
      'handsaw',
      'hammer'  => { claw => 1 },
    ],
    cutters => [ qw(circsaw handsaw), circsaw => { -as => 'buzzsaw' } ],
  },
  collectors => [
    'defaults',
    'brand_preference' => sub { 0 },
  ]
};

sub faux_exporter {
  my ($verbose) = @_;

  my @exported;

  my $reset = sub { @exported = () };

  my $export = sub {
    my ($class, $generator, $name, $arg, $collection, $as, $into) = @_;
    my $everything = { 
      class      => $class,
      generator  => $generator,
      name       => $name,
      arg        => $arg,
      collection => $collection,
      as         => $as,
      into       => $into,
    };
    push @exported, [ $name, ($verbose ? $everything : $arg) ];
  };

  return ($reset, $export, \@exported);
}

{
  my ($reset, $export, $exports) = faux_exporter;
  my $code = sub {
    $reset->();
    Sub::Exporter::build_exporter($config, { export => $export })->(@_);
  };

  $code->('Tools::Power');
  is_deeply(
    $exports,
    [ [ handsaw => {} ], [ hammer => { claw => 1 } ] ],
    "exporting with no arguments gave us default group"
  );

  $code->('Tools::Power', ':all');
  is_deeply(
    [ sort { $a->[0] cmp $b->[0] } @$exports ],
    [ map { [ $_ => {} ] } sort qw(circsaw drill handsaw nailgun hammer), ],
    "exporting :all gave us all exports",
  );

  $code->('Tools::Power', drill => { -as => 'auger' });
  is_deeply(
    $exports,
    [ [ drill => {} ] ],
    "'-as' parameter is not passed to generators",
  );

  $code->('Tools::Power', ':cutters');
  is_deeply(
    $exports,
    [ [ circsaw => {} ], [ handsaw => {} ], [ circsaw => {} ] ], 
    "group with two export instances of one export",
  );

  eval { $code->('Tools::Power', 'router') };
  like($@, qr/not exported/, "can't export un-exported export (got that?)");

  eval { $code->('Tools::Power', ':sockets') };
  like($@, qr/not exported/, "can't export nonexistent group, either");

  # because the brand_preference validator always fails, this should die
  eval { $code->('Tools::Power', brand_preference => [ '...' ]) };
  like(
    $@,
    qr/brand_preference failed validation/,
    "collector validator prevents bad export"
  );
}

{
  my ($reset, $export, $exports) = faux_exporter;
  my $code = sub {
    $reset->();
    Sub::Exporter::build_exporter(
      { exports => [ 'foo' ] },
      { export => $export }
    )->(@_);
  };

  $code->('Example::Foo');
  is_deeply(
    $exports,
    [ ],
    "exporting with no arguments gave us default default group, i.e., nothing"
  );

  $code->('Tools::Power', ':all');
  is_deeply(
    [ sort { $a->[0] cmp $b->[0] } @$exports ],
    [ map { [ $_ => {} ] } sort qw(foo), ],
    "exporting :all gave us all exports, i.e., foo",
  );
}

{
  package Test::SubExport::FAUX;
  my ($reset, $export, $exports) = main::faux_exporter;

  Sub::Exporter::setup_exporter({ exports => [ 'X' ] }, { export => $export });
  __PACKAGE__->import(':all');

  main::is_deeply($exports, [ [ X => {} ] ], "setup (not built) exporter");
}
