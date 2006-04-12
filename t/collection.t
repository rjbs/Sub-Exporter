#!perl -T
use strict;
use warnings;

=head1 TEST PURPOSE

These tests exercise the handling of collections in the exporter option lists.

=cut

use Test::More tests => 5;

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
    cutters => [ qw(circsaw handsaw), circsaw => { as => 'buzzsaw' } ],
  },
  collectors => [
    'defaults',
    'brand_preference' => sub { 0 },
    'model_preference' => sub { 1 },
  ]
};

$config->{$_} = Data::OptList::expand_opt_list($config->{$_})
  for qw(exports collectors);

{
  my $collection = Sub::Exporter::_collect_collections(
    $config, 
    [ [ circsaw => undef ], [ defaults => { foo => 1, bar => 2 } ] ],
  );

  is_deeply(
    $collection,
    { defaults => { foo => 1, bar => 2 } },
    "collection returned properly from collector",
  );
}

{
  my $arg = [ [ defaults => [ 1 ] ], [ defaults => { foo => 1, bar => 2 } ] ];

  eval { Sub::Exporter::_collect_collections($config, $arg); };
  like(
    $@,
    qr/collection \S+ provided multiple/,
    "can't provide multiple collection values",
  );
}

{
  # because the brand_preference validator always fails, this should die
  my $arg = [ [ brand_preference => [ 1, 2, 3 ] ] ];
  eval { Sub::Exporter::_collect_collections($config, $arg) };
  like(
    $@,
    qr/brand_preference failed validation/,
    "collector validator prevents bad export"
  );
}

{
  my $arg = [ [ model_preference => [ 1, 2, 3 ] ] ];
  my $collection = Sub::Exporter::_collect_collections($config, $arg);
  is_deeply(
    $collection,
    { model_preference => [ 1, 2, 3 ] },
    "true-returning validator allows collection",
  );
}
